# encoding: utf-8
class GpArticle::Content::Setting < Cms::ContentSetting
  set_config :gp_category_content_category_type_id, :name => '汎用カテゴリタイプ',
    :options => lambda { GpCategory::Content::CategoryType.all.map {|ct| [ct.name, ct.id] } }
  set_config :gp_template_content_template_id, :name => 'テンプレート',
    :options => lambda { GpTemplate::Content::Template.all.map {|t| [t.name, t.id] } }
  set_config :allowed_attachment_type, :name => '添付ファイル/許可する種類',
    :comment => '（例 gif,jpg,png,pdf,doc,xls,ppt,odt,ods,odp ）'
  set_config :word_dictionary, :name => "本文/単語変換辞書",
    :form_type => :text, :lower_text => "CSV形式（例　対象文字,変換後文字 ）"
  set_config :date_style, :name => "#{GpArticle::Doc.model_name.human}日付形式",
    :comment => I18n.t('comments.date_style').html_safe
  set_config :list_style, :name => "#{GpArticle::Doc.model_name.human}表示形式",
    :form_type => :text_area, :comment_upper => I18n.t('comments.doc_style').html_safe
  set_config :calendar_relation, :name => '汎用カレンダー',
    :options => GpArticle::Content::Doc::CALENDAR_RELATION_OPTIONS,
    :form_type => :radio_buttons
  set_config :tag_content_tag_id, :name => '関連ワード',
    :options => lambda { Tag::Content::Tag.all.map {|t| [t.name, t.id] } }
  set_config :save_button_states, :name => '保存ボタン',
#TODO: 暫定として即時公開のみ
    :options => GpArticle::Doc::STATE_OPTIONS.reject {|o| o.last != 'public' },
#    :options => GpArticle::Doc::STATE_OPTIONS,
    :form_type => :check_boxes
  set_config :map_relation, :name => 'マップ',
    :options => GpArticle::Content::Doc::MAP_RELATION_OPTIONS,
    :form_type => :radio_buttons
  set_config :display_dates, :name => '記事日付表示',
    :options => [['公開日', 'published_at'], ['最終更新日', 'updated_at']],
    :form_type => :check_boxes
  set_config :inquiry_setting, :name => '連絡先',
    :options => [['使用する', 'enabled'], ['使用しない', 'disabled']]

  INQUIRY_STATES = [['表示', 'visible'], ['非表示', 'hidden']]
  INQUIRY_FIELDS = [['課', 'group_id'], ['室・担当', 'charge'], ['電話番号', 'tel'], ['ファクシミリ', 'fax'], ['メールアドレス', 'email']]
  set_config :approval_relation, :name => '承認フロー',
    :options => GpArticle::Content::Doc::APPROVAL_RELATION_OPTIONS,
    :form_type => :radio_buttons

  def upper_text
    config[:upper_text].to_s
  end

  def lower_text
    config[:lower_text].to_s
  end

  def category_type_ids
    extra_values[:category_type_ids] || []
  end

  def visible_category_type_ids
    extra_values[:visible_category_type_ids] || []
  end

  def default_category_type_id
    extra_values[:default_category_type_id] || 0
  end

  def default_category_id
    extra_values[:default_category_id] || 0
  end

  def template_ids
    extra_values[:template_ids] || []
  end

  def default_template_id
    extra_values[:default_template_id] || 0
  end

  def default_inquiry_setting
    {
      display_fields: ['group_id', 'charge', 'tel', 'fax', 'email'],
      require_fields: ['group_id', 'tel', 'email'],
    }
  end
end
