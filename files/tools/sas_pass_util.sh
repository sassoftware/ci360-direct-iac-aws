#!/usr/bin/env bash
# Copyright © 2023, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved. 
# SPDX-License-Identifier: Apache-2.0


export CLASSPATH=/sas/sashome/SASVersionedJarRepository/eclipse/plugins/sas.core_904800.0.0.20221221190000_v940m8/sas.core.jar:/sas/sashome/SASVersionedJarRepository/eclipse/plugins/Log4J2_2.17.2.0_SAS_20220502101211/*
JAVA_HOME=/sas/sashome/SASPrivateJavaRuntimeEnvironment/9.4/jre

TMPFILE=$(mktemp --suffix .java)
cat << EOF > $TMPFILE
import com.sas.util.SasPasswordString;

public class Main {
    public static void main(String[] args) throws Exception {
        var method = args[0];
        var pass = args[1];
        if (method.equals("encode"))
            System.out.println(SasPasswordString.encode(pass));
        else
            System.out.println(SasPasswordString.decode(pass));
    }
}
EOF

$JAVA_HOME/bin/java $TMPFILE $1 $2