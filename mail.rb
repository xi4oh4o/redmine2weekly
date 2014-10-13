require 'mail'

def sendWeekPost(to, from, subject, text)

  Mail.defaults do
    delivery_method :smtp, {
      :port      => ::CONF['Smtp']['port'],
      :address   => ::CONF['Smtp']['address'],
      :user_name => ::CONF['Smtp']['user_name'],
      :password  => ::CONF['Smtp']['password'],
    }
  end

  Mail.deliver do
    to      to
    from    from
    subject subject
    html_part do
      body text
    end
  end
end
