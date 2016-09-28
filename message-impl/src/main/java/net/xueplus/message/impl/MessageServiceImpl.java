package net.xueplus.message.impl;

import net.xueplus.common.response.OptResult;
import net.xueplus.message.api.IMessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;
import org.springframework.stereotype.Component;

import javax.mail.Message;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

/**
 * <h1>消息服务实现</h1>
 * Created by zhangtao on 16/9/11.
 */
@Component
public class MessageServiceImpl implements IMessageService {
    /**
     * mail sender
     */
    @Autowired
    private JavaMailSender mailSender;
    /**
     * <h1>发送email</h1>
     *
     * @param to      邮件接受者
     * @param subject 主题
     * @param content 内容
     * @return 操作结果
     */
    public OptResult sendEmail(final String to, final String subject, final String content) {
        MimeMessagePreparator preparator = new MimeMessagePreparator() {
            public void prepare(MimeMessage mimeMessage) throws Exception {
                mimeMessage.setRecipient(Message.RecipientType.TO, new InternetAddress(to));
                mimeMessage.setFrom(new InternetAddress("mail@mycompany.com"));
                mimeMessage.setSubject(subject);
                mimeMessage.setText(content);
            }
        };

        //mailSender.send(preparator);
        System.out.println(content);
        return OptResult.success();
    }
}
