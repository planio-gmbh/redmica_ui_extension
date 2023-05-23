# frozen_string_literal: true

require_dependency 'application_helper'

module PreviewAttachment
  module ApplicationHelperPatch
    def self.included(base)
      base.send(:prepend, InstanceMethods)
    end

    module InstanceMethods
      def link_to_attachment(attachment, options={})
        original_link = super(attachment, options.dup)
        return original_link unless Setting.enabled_redmica_ui_extension_feature?('preview_attachment')
        return original_link unless options[:class].to_s.include?('icon-download')
        # do not render preview icon on attachments#show
        return original_link if params[:controller] == 'attachments' && params[:action] == 'show'
        image_extensions = Redmine::MimeType::MIME_TYPES.filter {|k,_| k=~/^image/ }.values.join(',').split(',')
        video_extensions = Redmine::MimeType::MIME_TYPES.filter {|k,_| k=~/^video/ }.values.join(',').split(',')
        #pdf_extensions = Redmine::MimeType::MIME_TYPES.filter {|k,_| k=~/^application\/pdf/ }.values.join(',').split(',')

        bp_src = if attachment.is_image? && attachment.extension_in?(image_extensions)
                   'imgSrc'
                 elsif attachment.is_video? && attachment.extension_in?(video_extensions)
                   'vidSrc'
                 # MEMO: Audio is excluded from preview.
                 #elsif attachment.is_audio?
                 #  'audio'

                 # this does not work. It either downloads the PDF or, when changing the URL to include dl=0, tries to interpret it as the HTML content for the iframe)
                 #elsif attachment.is_pdf? && attachment.extension_in?(pdf_extensions)
                 #  'iframeSrc'
                 else
                   nil
                 end
        return original_link unless bp_src

        filename = attachment.filename
        url = download_named_attachment_url(attachment, { filename: filename })
        content_tag('span', '', :class => 'preview-attachment icon-only icon-zoom-in',
                    :data => { :bp => filename, :bp_src => bp_src, :url => url },
                    :onclick => 'previewAttachment(this)') + original_link
      end
    end
  end
end
