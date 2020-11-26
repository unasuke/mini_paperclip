# frozen_string_literal: true

module MiniPaperclip
  module Storage
    class S3 < Base
      def write(style, file)
        debug("writing by S3 to bucket:#{@config.s3_bucket_name},key:#{s3_object_key(style)}")
        Aws::S3::Client.new.put_object(
          acl: @config.s3_acl,
          cache_control: @config.s3_cache_control,
          content_type: @record.read_attribute("#{@attachment_name}_content_type"),
          body: file.tap(&:rewind),
          bucket: @config.s3_bucket_name,
          key: s3_object_key(style),
        )
      end

      def copy(style, from_attachment)
        raise "not supported yet" unless from_attachment.storage.instance_of?(S3)
        debug("copying by S3 to bucket:#{@config.s3_bucket_name},key:#{s3_object_key(style)}")
        Aws::S3::Client.new.copy_object(
          acl: @config.s3_acl,
          cache_control: @config.s3_cache_control,
          content_type: @record.read_attribute("#{@attachment_name}_content_type"),
          copy_source: from_attachment.storage.object_key(style),
          bucket: @config.s3_bucket_name,
          key: s3_object_key(style),
        )
      end

      def s3_object_key(style)
        interpolate(@config.url_path, style)
      end

      def host
        # AWS CloudFront origin should be attached bucket name
        @config.s3_host_alias || "#{@config.s3_bucket_name}.#{@config.url_host}"
      end

      def exists?(style)
        res = Aws::S3::Client.new.head_object(
          bucket: @config.s3_bucket_name,
          key: s3_object_key(style),
        )
        res.content_length.to_i != 0
      end
    end
  end
end