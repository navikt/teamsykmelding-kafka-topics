# teamsykmelding-kafka-topics
Repo for Team Sykmelding sine kafkatopics, og kafkacat-oppsett.

> **Note**
> Dette er er eit repo kun for teamsykmelding om kafka topicene vi har, som ikke er av allmenn interesse. 
> Vi har derfor valgt å holde dette repoet lukket

## Bruk av kafkacat
Med kafkacat kan du sjekke hva som ligger på kafkatopics, og du kan sende meldinger til topicene. Vi gjør dette ved å 
bruke credentials og config fra en pod/container som har tilgang til det vi har behov for. 

Slik kommer du i gang: 
1. Installer kafkacat 
2. Clone dette repoet
3. Ved behov: Logg inn på gcp (`gcloud auth login`) og på aiven-prod i naisdevice
4. Bruk kubernetes for å finne applikasjonsnavn (container) som du skal bruke for å hente credentials
5. Kjør script i tools-mappen for å sette opp riktig config, f.eks. slik: 

`./forKafkacat.sh <appnavn> <gcp|fss> <appnavn>.config` 

`./forKafkacat.sh my-app gcp my-app.config`

Nå har du det du trenger for å gjøre ting mot topicene! 

### Noen nyttige kafkacat-kommandoer
Lese en melding fra topic: 
``kafkacat -F <container>.config -C -t <topic> -o 1 -c 1``

`-C` betyr consumer mode, `-o` angir offset og `-c` sier hvor mange meldinger man skal lese. 

Skrive til en topic: 
``kafkacat -F ~/.config/<container>.config -P -t <topic> -k <key> melding.json``

Her er `-P` producer mode. Det er lurt å lagre json-meldingen i en egen fil. 

## Bruk av kafka-consumer-groups
Kafka-consumer-groups lar deg se hvilke topics en consumer lytter på, samt offset og eventuelt lag for disse. Du kan 
også sette offset manuelt. For å bruke kafka-consumer-groups må du gjøre følgende: 
1. Logg inn på gcp (`gcloud auth login`) og på aiven-prod i naisdevice
2. Kjør script i tools-mappen for å sette opp riktig config, f.eks. slik:

`./forJavaClient.sh <appnavn> <gcp|fss> <appnavn>.config`

### Noen nyttige kommandoer for kafka-consumer-groups
Se informasjon om en consumer: 

``kafka-consumer-groups --command-config ~/.config/<appnavn>.config --bootstrap-server nav-prod-kafka-nav-prod.aivencloud.com:26484 --group <consumerGroupName> --describe``

Sette offset for en gitt topic basert på timestamp: 

``kafka-consumer-groups --command-config ~/.config/<appnavn>.config --bootstrap-server nav-prod-kafka-nav-prod.aivencloud.com:26484 --group <consumerGroupName>  --topic <topic> --reset-offsets --to-datetime '2021-12-05T00:00:00.000' --execute``

OBS: For å endre offset må consumeren tas helt ned, f.eks. ved å slette deploymenten. 
