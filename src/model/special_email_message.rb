module LambdaMail
  module Model
    class SpecialEmailMessage
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :subject, Text
      property :body, Text
      property :recipient, Text
      property :sent, Boolean, default: false
      property :sidekiq_job_id, Text, default: ''

      def send
        raise 'already sent' if sent
        raise 'already assigned a job' if sidekiq_job_id != ''

        job_id = Mailing::SendSpecialEmailMessageWorker.perform_async(
          id,
          true
        )
        p job_id
        self.sidekiq_job_id = job_id
        self.save!
      end
    end
  end
end
