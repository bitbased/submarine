class DropboxController < ApplicationController


  def show
  end

  def upload
    render :text => "UPLOADING"
  end

  def index
    
    AWS::S3::Base.establish_connection!(
      :access_key_id     => SubmarineAccount.current_account.aws_access_key_id,
      :secret_access_key => SubmarineAccount.current_account.aws_secret_access_key
    )

    bk = AWS::S3::Bucket.find(SubmarineAccount.current_account.aws_s3_bucket)

    @aws_objects = bk.objects

  end


  def _index
    AWS::S3::Base.establish_connection!(
      :access_key_id     => SubmarineAccount.current_account.aws_access_key_id,
      :secret_access_key => SubmarineAccount.current_account.aws_secret_access_key
    )

    bk = AWS::S3::Bucket.find(SubmarineAccount.current_account.aws_s3_bucket)

    @aws_objects = bk.objects

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        render json: {
          policy: s3_upload_policy_document,
          signature: s3_upload_signature,
          key: "uploads/#{SecureRandom.uuid}/#{params[:doc][:title]}",
          success_action_redirect: "/"
        }
      }
    end

  end

  # generate the policy document that amazon is expecting.
  def _s3_upload_policy_document
    Base64.encode64(
      {
        expiration: 30.days.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
        conditions: [
          { bucket: SubmarineAccount.current_account.aws_s3_bucket },
          { acl: 'public-read' },
          ["starts-with", "$key", "uploads/"],
          { success_action_status: '201' }
        ]
      }.to_json
    ).gsub(/\n|\r/, '')
  end

  # sign our request by Base64 encoding the policy document.
  def _s3_upload_signature
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        SubmarineAccount.current_account.aws_access_key_id,
        s3_upload_policy_document
      )
    ).gsub(/\n/, '')
  end




end