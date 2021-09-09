# teamsykmelding-kafka-topics
Repo for Team Sykmelding sine kafkatopics, og kafkacat-oppsett.

## Bruk av kafkacat
Med kafkacat kan du sjekke hva som ligger på kafkatopics, og du kan sende meldinger til topicene. Vi gjør dette ved å 
bruke credentials og config fra en pod som har tilgang til det vi har behov for. 

Slik kommer du i gang: 
1. Installer kafkacat 
2. Clone dette repoet
3. Ved behov: Logg inn på gcp (`gcloud auth login`) og på aiven-prod i naisdevice
4. Bruk kubernetes for å finne pod-navn som du skal bruke for å hente credentials
5. Kjør script i tools-mappen for å sette opp riktig config, f.eks. slik: 
`./forKafkacat.sh <podnavn> <gcp|fss> <appnavn>.config`

Nå har du det du trenger for å gjøre ting mot topicene! 

### Noen nyttige kommandoer
Lese en melding fra topic: 
``kafkacat -F <appnavn>.config -C -t <topic> -o 1 -c 1``

`-C` betyr consumer mode, `-o` angir offset og `-c` sier hvor mange meldinger man skal lese. 

Skrive til en topic: 
``kafkacat -F ~/.config/<appnavn>.config -P -t <topic> -k <key> melding.json``

Her er `-P` producer mode. Det er lurt å lagre json-meldingen i en egen fil. 