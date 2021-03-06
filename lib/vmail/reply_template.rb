require 'mail'
require 'time'

module Vmail
  class ReplyTemplate

    def initialize(mail, username, name, replyall)
      @username, @name, @replyall = username, name, replyall
      @mail = Mail.new(mail)
    end

    def reply_headers(try_again = true)
      formatter = Vmail::MessageFormatter.new(@mail)
      @orig_headers = formatter.extract_headers
      subject = @orig_headers['subject']
      if subject !~ /Re: /
        subject = "Re: #{subject}"
      end
      date = @orig_headers['date'].is_a?(String) ? Time.parse(@orig_headers['date']) : @orig_headers['date']
      quote_header = date ? "On #{date.strftime('%a, %b %d, %Y at %I:%M %p')}, #{sender} wrote:\n\n" : "#{sender} wrote:\n\n"
      body = quote_header + formatter.process_body.gsub(/^(?=>)/, ">").gsub(/^(?!>)/, "> ")
      {'from' => "#@name <#@username>", 'to' => primary_recipient, 'cc' => cc, 'subject' => subject, :body => body}
    end

    def primary_recipient
      reply_headers unless @orig_headers
      from = @orig_headers['from']
      reply_to = @orig_headers['reply-to']
      [ reply_to, from ].flatten.compact.map(&:to_s)[0]
    end

    def cc
      return nil unless @replyall
      cc = @mail.header['to'].value.split(/,\s*/) 
      if @mail.header['cc']
        cc += @mail.header['cc'].value.split(/,\s*/) 
      end
      cc = cc.flatten.compact.
        select {|x| 
          x.to_s[/<([^>]+)>/, 1] !~ /#{@username}/ && x.to_s[/^[^<]+/, 1] !~ /#{@name}/
          }.join(', ')
    end

    def sender
      @mail.header['from'].value
    end

    # deprecated
    def address_to_string(x)
      x.name ? "#{x.name} <#{x.mailbox}@#{x.host}>" : "#{x.mailbox}@#{x.host}"
    end

  end
end
