package cn.xueplus.container;

import org.slf4j.MDC;

import com.alibaba.dubbo.common.utils.ConfigUtils;
import com.alibaba.dubbo.container.Main;

public class ContainerBootstrap {

    public static void main(String[] args) throws Exception {
        initContext();
        Main.main(null);
    }

    private static void initContext() {
        String module = ConfigUtils.getProperty("dubbo.application.name");
        MDC.put("module", module);
    }
}