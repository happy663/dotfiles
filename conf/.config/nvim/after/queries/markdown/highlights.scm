;; extends

;; Markdownの見出しの優先度を上げて、@spell.markdownよりも優先させる
;; デフォルト: 100 → 変更後: 110
;; 注: ファイルタイプ(.markdown)は自動的に追加されるため、含めない

(atx_heading
  (atx_h1_marker)
  heading_content: _ @markup.heading.1
  (#set! priority 110))

(atx_heading
  (atx_h2_marker)
  heading_content: _ @markup.heading.2
  (#set! priority 110))

(atx_heading
  (atx_h3_marker)
  heading_content: _ @markup.heading.3
  (#set! priority 110))

(atx_heading
  (atx_h4_marker)
  heading_content: _ @markup.heading.4
  (#set! priority 110))

(atx_heading
  (atx_h5_marker)
  heading_content: _ @markup.heading.5
  (#set! priority 110))

(atx_heading
  (atx_h6_marker)
  heading_content: _ @markup.heading.6
  (#set! priority 110))

