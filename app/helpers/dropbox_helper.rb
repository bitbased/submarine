module DropboxHelper

  def s3_uploader_form(options = {}, &block)
    uploader = S3Uploader.new(options)
    form_tag(uploader.url, uploader.form_options) do
      uploader.fields.map do |name, value|
      hidden_field_tag(name, value)
      end.join.html_safe + capture(&block)
    end
  end




  class S3Uploader
    def initialize(options)
      @options = options.reverse_merge(
        id: "fileupload",
        aws_access_key_id: SubmarineAccount.current_account.aws_access_key_id,
        aws_secret_access_key: SubmarineAccount.current_account.aws_secret_access_key,
        bucket: SubmarineAccount.current_account.aws_s3_bucket,
        acl: "public-read",
        expiration: 30.days.from_now,
        max_file_size: 100.megabytes,
        as: "file"
      )
    end

    def form_options
      {
        id: @options[:id],
        method: "post",
        authenticity_token: false,
        multipart: true,
        data: {
          post: @options[:post],
          as: @options[:as]
        }
      }
    end

    def fields
      {
        :key => key,
        :acl => @options[:acl],
        :policy => policy,
        :signature => signature,
        "AWSAccessKeyId" => @options[:aws_access_key_id],
      }
    end

    def key
      @key ||= "uploads/#{SecureRandom.hex}/${filename}"
    end

    def url
      "http://#{@options[:bucket]}.s3.amazonaws.com/"
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", "")
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          ["starts-with", "$utf8", ""],
          ["starts-with", "$key", ""],
          ["content-length-range", 0, @options[:max_file_size]],
          {bucket: @options[:bucket]},
          {acl: @options[:acl]}
        ]
      }
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          @options[:aws_secret_access_key], policy
        )
      ).gsub("\n", "")
    end
  end


end
