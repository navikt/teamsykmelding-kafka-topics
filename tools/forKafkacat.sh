#!/bin/bash
container=$1
if [ -z "$container" ]; then echo "Container must not be null" && exit 0; fi
pod=$(kubectl get pods | egrep -m 1 "($container-[0-9a-z]{10}-[0-9a-z]{5})" -o)
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
cp=~/.config/kafka/$context/$appname

[ -d $cp ] || mkdir -p $cp
[ -d ~/.config ] || mkdir ~/.config
rm -f $configFile
if [[ $kafkaCluster == *"gcp" ]]; then
    kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $KAFKA_PRIVATE_KEY_PATH') -c $container $cp/kafka.key
    kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $KAFKA_CA_PATH') -c $container $cp/ca.crt
    kubectl cp $pod:$(kubectl exec $pod -c $container -- sh -c 'readlink -f $KAFKA_CERTIFICATE_PATH') -c $container $cp/kafka.crt
    echo "bootstrap.servers="$(kubectl exec $pod -c $container -- sh -c 'echo $KAFKA_BROKERS') >> $configFile
    echo "security.protocol=ssl" >> $configFile
    echo "ssl.key.location=$cp/kafka.key" >> $configFile
    echo "ssl.certificate.location=$cp/kafka.crt" >> $configFile
    echo "ssl.ca.location=$cp/ca.crt" >> $configFile
    echo "enable.ssl.certificate.verification=false" >> $configFile
elif [[ $kafkaCluster == *"fss" ]]; then
    if [[ $context == "prod"* ]]; then
        echo "bootstrap.servers=a01apvl00145.adeo.no:8443,a01apvl00146.adeo.no:8443,a01apvl00147.adeo.no:8443,a01apvl00148.adeo.no:8443,a01apvl00149.adeo.no:8443,a01apvl00150.adeo.no:8443" >> $configFile
    elif [[ $context == "dev"* ]]; then
        echo "bootstrap.servers=b27apvl00045.preprod.local:8443,b27apvl00046.preprod.local:8443,b27apvl00047.preprod.local:8443" >> $configFile
    fi
        username=$(kubectl exec $pod -c $container -- sh -c 'cat /secrets/serviceuser/username')
        password=$(kubectl exec $pod -c $container -- sh -c 'cat /secrets/serviceuser/password')
        if [ -z "$username" ]
        then
            username=$(kubectl exec $pod -c $container -- sh -c 'echo $SERVICEUSER_USERNAME')
            password=$(kubectl exec $pod -c $container -- sh -c 'echo $SERVICEUSER_PASSWORD')
        fi
        echo "security.protocol=SASL_SSL" >> $configFile
        echo "sasl.mechanism=PLAIN" >> $configFile
        echo "sasl.username=$username" >> $configFile
        echo "sasl.password=$password" >> $configFile
        echo "enable.ssl.certificate.verification=false" >> $configFile
fi
