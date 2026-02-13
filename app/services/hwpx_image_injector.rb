# frozen_string_literal: true

require "zip"
require "securerandom"

# HWPX(ZIP) 파일에 PNG 이미지를 삽입하는 서비스
# HWPX는 OWPML(KS X 6101) 표준 기반 ZIP 아카이브
# 구조: BinData/ → 바이너리, Contents/content.hpf → 매니페스트, Contents/section0.xml → 본문
class HwpxImageInjector
  class InjectionError < StandardError; end

  # HWPX 단위: 1px ≈ 75 HWP units (25.4 × 283.465 / 96)
  PX_TO_HWPUNIT = 75
  # 최대 폭: 150mm ≈ 42520 HWP units
  MAX_WIDTH_HWPUNIT = 42_520

  NS_HP = "http://www.hancom.co.kr/hwpml/2011/paragraph"
  NS_HC = "http://www.hancom.co.kr/hwpml/2011/core"
  NS_HS = "http://www.hancom.co.kr/hwpml/2011/section"
  NS_OPF = "http://www.idpf.org/2007/opf/"

  def initialize(hwpx_data)
    @hwpx_data = hwpx_data
  end

  # PNG 이미지를 HWPX에 삽입하고 수정된 바이너리를 반환
  # @param png_data [String] PNG 바이너리 데이터
  # @param width_px [Integer] 이미지 폭 (픽셀)
  # @param height_px [Integer] 이미지 높이 (픽셀)
  # @param position [Symbol] 삽입 위치 (:after_first_heading, :before_last_section)
  # @return [String] 수정된 HWPX 바이너리
  def inject_image(png_data, width_px: 460, height_px: 420, position: :after_first_heading)
    img_id = "IMG_#{SecureRandom.hex(4).upcase}"
    bin_filename = "#{img_id}.png"

    output = StringIO.new
    output.binmode

    Zip::OutputStream.write_buffer(output) do |zos|
      Zip::InputStream.open(StringIO.new(@hwpx_data)) do |zis|
        while (entry = zis.get_next_entry)
          data = zis.read

          if entry.name == "Contents/content.hpf"
            data = inject_manifest_item(data, img_id, bin_filename)
          elsif entry.name == "Contents/section0.xml"
            data = inject_picture_paragraph(data, img_id, bin_filename, width_px, height_px, position)
          end

          zos.put_next_entry(entry.name)
          zos.write(data)
        end
      end

      # BinData/ 폴더에 PNG 추가
      zos.put_next_entry("BinData/#{bin_filename}")
      zos.write(png_data)
    end

    output.rewind
    output.string
  rescue Zip::Error => e
    raise InjectionError, "HWPX ZIP 처리 중 오류: #{e.message}"
  rescue => e
    Rails.logger.error("[HwpxImageInjector] #{e.class}: #{e.message}")
    # Graceful degradation: 이미지 삽입 실패 시 원본 HWPX 반환
    @hwpx_data
  end

  private

  # content.hpf 매니페스트에 이미지 항목 추가
  def inject_manifest_item(hpf_xml, img_id, bin_filename)
    item_entry = %(<opf:item id="#{img_id}" href="BinData/#{bin_filename}" media-type="image/png" isEmbeded="1"/>)

    insert_pos = hpf_xml.index("</opf:manifest>")
    if insert_pos
      hpf_xml.insert(insert_pos, "    #{item_entry}\n  ")
    else
      hpf_xml
    end
  end

  # section0.xml에 이미지 단락 삽입
  def inject_picture_paragraph(section_xml, img_id, bin_filename, width_px, height_px, position)
    # hc 네임스페이스가 없으면 추가
    unless section_xml.include?('xmlns:hc=')
      section_xml = section_xml.sub(
        'xmlns:hs=',
        'xmlns:hc="http://www.hancom.co.kr/hwpml/2011/core" xmlns:hs='
      )
    end

    # 이미지 크기 계산 (HWP units)
    w_hwp = [width_px * PX_TO_HWPUNIT, MAX_WIDTH_HWPUNIT].min
    h_hwp = if width_px * PX_TO_HWPUNIT > MAX_WIDTH_HWPUNIT
      (height_px.to_f / width_px * MAX_WIDTH_HWPUNIT).round
    else
      height_px * PX_TO_HWPUNIT
    end

    pic_xml = build_picture_paragraph(img_id, bin_filename, w_hwp, h_hwp)

    case position
    when :after_first_heading
      insert_after_first_heading(section_xml, pic_xml)
    when :before_last_section
      insert_before_last_closing(section_xml, pic_xml)
    else
      insert_after_first_heading(section_xml, pic_xml)
    end
  end

  # OWPML 이미지 단락 XML 생성
  def build_picture_paragraph(img_id, bin_filename, w_hwp, h_hwp)
    instid = SecureRandom.random_number(2**31)

    <<~XML
      <hp:p paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
        <hp:run charPrIDRef="0">
          <hp:pic id="#{instid}" zOrder="0" numberingType="NONE" textWrap="TOP_AND_BOTTOM" textFlow="BOTH_SIDES" lock="0" dropcapstyle="None" href="" groupLevel="0" instid="#{instid}" reverse="0">
            <hp:offset x="0" y="0"/>
            <hp:orgSz width="#{w_hwp}" height="#{h_hwp}"/>
            <hp:curSz width="#{w_hwp}" height="#{h_hwp}"/>
            <hp:flip horizontal="0" vertical="0"/>
            <hp:rotationInfo angle="0" centerX="#{w_hwp / 2}" centerY="#{h_hwp / 2}" rotateImage="1"/>
            <hp:imgRect>
              <hp:pt0 x="0" y="0"/>
              <hp:pt1 x="#{w_hwp}" y="0"/>
              <hp:pt2 x="#{w_hwp}" y="#{h_hwp}"/>
              <hp:pt3 x="0" y="#{h_hwp}"/>
            </hp:imgRect>
            <hp:imgClip left="0" right="0" top="0" bottom="0"/>
            <hp:inMargin left="0" right="0" top="0" bottom="0"/>
            <hp:imgDim dimwidth="#{w_hwp}" dimheight="#{h_hwp}"/>
            <hp:sz width="#{w_hwp}" height="#{h_hwp}" widthRelTo="absolute" heightRelTo="absolute"/>
            <hp:pos treatAsChar="0" affectLSpacing="0" flowWithText="1" textWrap="topAndBottom" textFlow="bothSides" vertRelTo="para" horzRelTo="column" vertOffset="0" horzOffset="0"/>
            <hp:outMargin left="0" right="0" top="142" bottom="142"/>
            <hc:img binaryItemIDRef="#{img_id}" bright="0" contrast="0" effect="REAL_PIC" alpha="0"/>
          </hp:pic>
        </hp:run>
      </hp:p>
    XML
  end

  # 첫 번째 제목 단락 뒤에 이미지 삽입
  def insert_after_first_heading(section_xml, pic_xml)
    # 첫 번째 </hp:p> 뒤에 삽입 (제목 단락 이후)
    # secPr을 포함하는 첫 번째 p는 건너뜀 (문서 설정 단락)
    first_close = section_xml.index("</hp:p>")
    return section_xml + pic_xml unless first_close

    # secPr 다음의 두 번째 </hp:p> 찾기
    second_close = section_xml.index("</hp:p>", first_close + 7)
    if second_close
      insert_pos = second_close + 7
      section_xml.insert(insert_pos, "\n#{pic_xml}")
    else
      # 두 번째가 없으면 첫 번째 뒤에 삽입
      insert_pos = first_close + 7
      section_xml.insert(insert_pos, "\n#{pic_xml}")
    end
  end

  # 마지막 </hs:sec> 앞에 이미지 삽입
  def insert_before_last_closing(section_xml, pic_xml)
    insert_pos = section_xml.rindex("</hs:sec>")
    if insert_pos
      section_xml.insert(insert_pos, "#{pic_xml}\n")
    else
      section_xml + pic_xml
    end
  end
end
