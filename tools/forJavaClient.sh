#!/bin/bash
container=$1
if [ -z "$container" ]; then echo "Container must not be null" && exit 0; fi
pod=$(kubectl get pods | egrep -m 1 "($container-[0-9a-z]{5,10}-[0-9a-z]{5})" -o)
if [ -z "$pod" ]; then echo "did not find any pod for container $container" && exit 0; fi
echo $pod
kafkaCluster=$2
configFile=~/.config/kafkacat.conf
if [ ! -z "$3" ]
    then
        configFile=~/.config/$3
fi

echo $configFile

context=$(kubectl config current-context)
appname=$(kubectl exec $pod -c $container -- sh -c 'echo $NAIS_APP_NAME')
cp=~/.config/kafka/$context/syfonlaltinn

[ -d $cp ] || mkdir -p $cp
[ -d ~/.config ] || mkdir ~/.config
rm -f $configFile
if [[ $kafkaCluster == *"gcp" ]]; then
    kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $KAFKA_TRUSTSTORE_PATH') -c $container $cp/kafka.client.truststore.jks
    kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $KAFKA_KEYSTORE_PATH') -c $container $cp/kafka.client.keystore.jks
    truststorePassword=$(kubectl exec $pod -c $container -- sh -c 'echo $KAFKA_CREDSTORE_PASSWORD')
    echo "bootstrap.servers="$(kubectl exec $pod -c $container -- sh -c 'echo $KAFKA_BROKERS') >> $configFile
    echo "security.protocol=ssl" >> $configFile
    echo "ssl.truststore.location=$cp/kafka.client.truststore.jks" >> $configFile
    echo "ssl.keystore.location=$cp/kafka.client.keystore.jks" >> $configFile
    echo "ssl.truststore.password=$truststorePassword" >> $configFile
    echo "ssl.key.password=$truststorePassword" >> $configFile
    echo "ssl.keystore.password=$truststorePassword" >> $configFile
    echo "ssl.endpoint.identification.algorithm=" >> $configFile
elif [[ $kafkaCluster == *"fss" ]]; then
    if [[ $context == "prod"* ]]; then
        echo "bootstrap.servers=a01apvl00145.adeo.no:8443,a01apvl00146.adeo.no:8443,a01apvl00147.adeo.no:8443,a01apvl00148.adeo.no:8443,a01apvl00149.adeo.no:8443,a01apvl00150.adeo.no:8443" >> $configFile
    elif [[ $context == "dev"* ]]; then
        echo "bootstrap.servers=b27apvl00045.preprod.local:8443,b27apvl00046.preprod.local:8443,b27apvl00047.preprod.local:8443" >> $configFile
    fi
        kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $NAV_TRUSTSTORE_PATH') -c $container $cp/nav.truststore.jks
        username=$(kubectl exec $pod -c $container -- sh -c 'cat /secrets/serviceuser/username')
        password=$(kubectl exec $pod -c $container -- sh -c 'cat /secrets/serviceuser/password')
        if [ -z "$username" ]
        then
            username=$(kubectl exec $pod -c $container -- sh -c 'echo $SERVICEUSER_USERNAME')
            password=$(kubectl exec $pod -c $container -- sh -c 'echo $SERVICEUSER_PASSWORD')
        fi
        truststorePassword=$(kubectl exec $pod -c $container -- sh -c 'echo $NAV_TRUSTSTORE_PASSWORD')
        echo "ssl.truststore.location=$cp/nav.truststore.jks" >> $configFile
        echo "ssl.truststore.password=$truststorePassword" >> $configFile
        echo "sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="$username" password="$password";" >> $configFile
        echo "security.protocol=SASL_SSL" >> $configFile
        echo "sasl.mechanism=PLAIN" >> $configFile
        echo "session.timeout.ms=30000" >> $configFile
        echo "request.timeout.ms=40000" >> $configFile
fi
