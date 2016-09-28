package net.xueplus.message.api;

import net.xueplus.common.response.OptResult;

import java.io.Serializable;

/**
 * <h1>消息服务定义</h1>
 * Created by zhangtao on 16/9/11.
 */
public interface IMessageService extends Serializable {
    /**
     * <h1>发送email</h1>
     * @param to 邮件接受者
     * @param subject 主题
     * @param content 内容
     * @return 操作结果
     */
    OptResult sendEmail(String to, String subject, String content);
}
