#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

module AttachmentHelper
  # returns a string of html attributes suitable for use with $.loadDocPreview
  def doc_preview_attributes(attachment, attrs={})
    if attachment.crocodoc_available?
      begin
        attrs[:crocodoc_session_url] = attachment.crocodoc_url(@current_user, attrs[:crocodoc_ids])
      rescue => e
        Canvas::Errors.capture_exception(:crocodoc, e)
      end
    elsif attachment.canvadocable?
      attrs[:canvadoc_session_url] = attachment.canvadoc_url(@current_user)
    end
    attrs[:attachment_id] = attachment.id
    attrs[:mimetype] = attachment.mimetype
    context_name = url_helper_context_from_object(attachment.context)
    url_helper = "#{context_name}_file_inline_view_url"
    if self.respond_to?(url_helper)
      attrs[:attachment_view_inline_ping_url] = self.send(url_helper, attachment.context, attachment.id)
    end
    if attachment.pending_upload? || attachment.processing?
      attrs[:attachment_preview_processing] = true
    end
    attrs.inject("") { |s,(attr,val)| s << "data-#{attr}=#{val} " }
  end

  def media_preview_attributes(attachment, attrs={})
    attrs[:type] = attachment.content_type.match(/video/) ? 'video' : 'audio'
    attrs[:download_url] = context_url(attachment.context, :context_file_download_url, attachment.id)
    attrs[:media_entry_id] = attachment.media_entry_id if attachment.media_entry_id
    attrs.inject("") { |s,(attr,val)| s << "data-#{attr}=#{val} " }
  end

  def doc_preview_json(attachment, user)
    {
      canvadoc_session_url: attachment.canvadoc_url(@current_user),
      crocodoc_session_url: attachment.crocodoc_url(@current_user),
    }
  end
end
