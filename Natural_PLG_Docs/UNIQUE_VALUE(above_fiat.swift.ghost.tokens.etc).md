# RI_GIFT_PORTAL — Fra intensjon til etterprøvbar gaveflyt

## Teknologisk status, menneskelig samarbeid og verdi utover penger

## Kortversjon

RI_GIFT_PORTAL kombinerer:

- En barn-først-prioritering uttrykt i Solidity.
- Fordeling av ETH og ERC20-tokens.
- Signerte attestasjoner og offentlig hendelseslogging.
- Governance-token, Governor og Timelock.
- Publisert kildekode, Foundry-tester og deploy-artefakter.
- En visjon om åpen tilgang, gaveøkonomi og menneskelig ansvar.

Prosjektets motivasjon er større enn økonomisk avkastning. Kjærlighet, barns
verdighet og ansvar for fremtidige generasjoner er prosjektets etiske og
åndelige utgangspunkt.

Den tekniske oppgaven er konkret: gjøre utvalgte forpliktelser håndhevbare,
synlige og etterprøvbare, også når mennesker, roller og økonomiske forhold endres.

Dokumentet skiller derfor mellom:
1. Det den delte koden implementerer.
2. Det publiserte artefakter dokumenterer.
3. Det prosjektet ønsker å utvikle videre.

---

## 1) Hva som kjennetegner systemet

### A. Barn-først-grense i kode

`MIN_CHILD_FLOOR = 2500` basispunkter uttrykker et minimum på 25% i
kontraktens fordelingsparameter.

Konstruktøren og `setMinChildShareBps` avviser lavere innstillinger.

Dette gjør en etisk prioritering til en programmatisk begrensning:
en governance-beslutning kan ikke bare sette denne parameteren til null.

Avgrensninger:
- Fordelingen skjer i hele minste tokenenheter, med avrunding nedover.
- Grensen gjelder den ordinære distribusjonsbanen.
- Tilbakeholdte midler kan behandles gjennom andre beslutningsbaner.
- En overføring til `childAnchor` dokumenterer mottakeradressen, ikke
  automatisk at et bestemt barn har mottatt hjelp.

### B. Tak på operasjonsandelen

`MAX_FEE_CAP = 1000` basispunkter setter et tak på 10% for
operasjonsandelen i ordinær fordeling.

Utgangspunktet i det delte Sepolia-registeret er 5%.

Dette avgrenser én konkret avgiftskategori. Nettverksgebyrer,
valutaveksling og eventuelle kostnader etter videre overføring må
synliggjøres separat.

### C. Governance med forsinkelse

Arkitekturen består av:

- `PLGVotingToken`
- `PLGGovernor`
- `PLGTimelock`
- `PLGGiftRouter`

Når Timelock er routerens `validatorSet`, må privilegerte router-kall
komme fra Timelock.

Den tiltenkte beslutningsgangen er:

Forslag → avstemning → kø → tidsforsinkelse → utførelse.

Beskyttelsen avhenger også av korrekt rolleoppsett og hvem som faktisk
kontrollerer stemmemakten.

### D. Attestasjon og feilbane

Routeren implementerer EIP-712-basert signaturkontroll mot godkjente
attestorer.

Ved enkelte valideringsfeil registreres midlene som tilbakeholdt.
Governance kan deretter velge:

- `REFUND`
- `DONATE_TO_CHILD`
- `REROUTE`
- `LOCK`

En signatur dokumenterer hvem som har attestert bestemte data.
Den beviser ikke alene sannheten i en intensjon, et behov eller en
åndelig fortolkning.

### E. Offentlig etterprøvbarhet

Materialet inneholder:

- Solidity-kildekode.
- Enhetstester og governance-integrasjonstester.
- Foundry-konfigurasjon.
- Adresse- og parameterregister.
- Lokale deploy-logger.
- Sepolia-logger med transaksjonshasher og kvitteringer.

Dette er konkrete utviklingsartefakter, ikke bare en konseptbeskrivelse.

Det særegne ligger i sammensetningen og formålet. Påstand om global
teknologisk unikhet krever i tillegg sammenligning med andre løsninger.

---

## 2) Hva dette hjelper med

### Fra «stol på oss» til «undersøk selv»

En giver skal kunne forstå:

- Hvor mye som ble sendt.
- Hvilken kontrakt som behandlet gaven.
- Hvilke fordelingsparametere som gjaldt.
- Hvilke adresser som mottok midler.
- Om midler ble tilbakeholdt.
- Hvilket vedtak som senere endret deres status.

### Eksempel: 100 USDC

Med 25% barneandel og 5% operasjonsandel, godkjent attestasjon og aktive
vektede noder:

| Formål | Beløp |
|---|---:|
| ChildAnchor | 25 USDC |
| Operasjon | 5 USDC |
| Noder samlet | 70 USDC |

Uten aktive nodevekter sendes resten til ChildAnchor:
95 USDC til ChildAnchor og 5 USDC til operasjon.

Ved flere noder kan heltallsavrunding etterlate små restbeløp i routeren.

### Hvor sporbarheten slutter

Blockchain kan dokumentere overføring til en adresse.
For å følge hjelpen videre til mat, vann, skole eller helsehjelp trengs
også dokumentasjon fra den fysiske gjennomføringen.

Målet er sammenhengende sporbarhet fra A til Å, uten å forveksle en
on-chain-kvittering med dokumentasjon på hele sluttresultatet.

---

## 3) Dokumentert nåværende modenhet

### Implementert i delt kildekode

- ETH- og ERC20-donasjoner.
- Fordelingsberegning.
- Barn-først-parametergrense og avgiftstak.
- Attestorregister og signaturkontroll.
- Vektet nodefordeling.
- ETH-utbetaling til noder gjennom uttaksmodell.
- Hold-, refusjons- og omrutingsfunksjoner.
- Tokenbasert governance og Timelock-integrasjon.

### Dokumentert i delte deploy-artefakter

Sepolia-registeret og den avsluttede broadcast-loggen oppgir fire
deployede kontrakter og vellykkede kvitteringer for deploy- og
rolleoperasjoner.

Dette underbygger en testnet-implementering. Det er ikke i seg selv
en uavhengig sikkerhetsrevisjon eller dokumentasjon på produksjonsdrift.

### Ikke dokumentert som ferdig garanti

- Full sporbarhet frem til fysisk hjelp.
- Minimum 20 selvstendige deltakere.
- Forbud mot forslagstillers egen stemme.
- Automatisk håndtering av tapte wallets.
- Uavhengig revisjon eller bestemte R&D-labtester.
- Stabilitet over flere år.

Sepolia-deployen er datert august 2026 i registeret.
Genesis-hendelsen er en historisk registrering; den dokumenterer ikke
alene flerårig drift eller uforanderlighet i alle senere parametere.

---

## 4) Proof of Enforcement og governance-resiliens

### A. Hva «proof of enforcement» betyr her

Begrepet brukes som en beskrivende betegnelse, ikke som en etablert
sertifisering eller en ny blockchain-konsensusmekanisme.

Prinsippet er:

En erklært regel skal kunne undersøkes gjennom kode, tester og faktisk
utførelse — også når noen forsøker å bryte den.

For `MIN_CHILD_FLOOR` innebærer dette blant annet:
- Forsøk på å opprette router med for lav parameter avvises.
- Forsøk på å senke parameteren under gulvet avvises.
- Governance kan ikke omgå kontrollen gjennom vanlig parameterendring.

### B. Hva som fortsatt må inngå i beviset

En fullstendig barn-først-garanti må også dekke unntaksbanene.

I dagens delte kode kan:
- `REROUTE` sende hele et tilbakeholdt beløp til et valgt mål.
- `childAnchor` endres gjennom governance.
- Fordelingsparametere endres til en samlet verdi over 100%, slik at
  beregning eller distribusjon kan stoppe.

Parametergrensen er derfor reell, men er ikke en garanti om at enhver
innbetaling alltid gir minst 25% faktisk hjelp til barn.

### C. Verdi utover fiat og betalingsnettverk

Fiat, tokens og betalingsinfrastruktur beskriver økonomiske midler.
De beskriver ikke hele verdien av omsorg, tillit eller et barns trygghet.

Prosjektets åndelige motivasjon kan uttrykkes som universell kjærlighet.
Den tekniske dokumentasjonen må samtidig beskrive presist hvilke
forpliktelser maskinen faktisk håndhever.

De to perspektivene kan stå sammen uten at kode fremstilles som et
måleinstrument for menneskeverd eller sjel.

### D. Initiativtakeren er en deltaker, ikke en nødvendig hersker

Prosjektets mål er at initiativtakeren kan bli én deltaker blant mange,
uten varig særmakt og uten å være et nødvendig operasjonelt kontaktpunkt.

Ifølge initiativtakeren finnes kandidater til Core Actor-rollene.
De øvrige 16 validatorrollene er planlagt rekruttert over tid.

En rolleplan er ikke det samme som aktiv, uavhengig governance.
Dette etableres gjennom faktisk deltakelse, nøkkelfordeling,
stemmemakt og dokumentert ansvar.

### E. Planlagt menneskelig sikkerhetsnett

Målbildet omfatter:
- 1 000 000 PLG governance-tokens.
- Quorum på 4%.
- Minimum 20 selvstendige deltakere.
- Ingen stemme på eget forslag.
- Felles beslutning om nye deltakere.
- Rutiner for bortfall, sykdom og tap av nøkler.
- Bevart offentlig historikk ved wallet-erstatning.

Ved uendret totalforsyning tilsvarer 4% 40 000 tokens.
Dette er tokenvekt, ikke automatisk 20 personer.

De øvrige deltakerreglene er foreløpig et designmål, ikke implementert
av den viste Governor-kontrakten.

### F. «Én enhet» uten én kontrollerende hånd

Samarbeid betyr at alle roller teller, ikke at alle må være enige.

En robust modell trenger:
- Rett til saklig uenighet.
- Like regler for initiativtaker, venner og familie.
- Habilitetsregler og etterprøvbare beslutninger.
- Beskyttelse mot både maktkonsentrasjon og vilkårlig utestengelse.

Barnesikkerhet må bygge på konkrete rutiner og dokumenterte forhold,
ikke rykter eller personlige lojaliteter.

En tapt wallet blir ikke automatisk deaktivert på blockchain.
Å markere den som inaktiv i UI fjerner heller ikke dens tokenrettigheter.
Nøkkelgjenoppretting og erstatning krever en særskilt, sikkert utformet modell.

### G. PLGVotingToken-fondet — låst frem til full desentralisering

Prosjektets oppgitte fondmodell omfatter **360 000 PLGVotingTokens**,
tilsvarende **36% av totalforsyningen på 1 000 000 tokens**.

Disse skal være låst og kan først frigjøres når systemet er fullt
desentralisert. Frigjøring skal dermed være knyttet til oppfylte
desentraliseringsvilkår — ikke bare til tid eller initiativtakerens ønske.

Dette supplerer barn-først-prinsippet:
- `MIN_CHILD_FLOOR` begrenser den ordinære gavefordelingen.
- Fondslåsen skal begrense tilgangen til den reserverte tokenbeholdningen
  frem til den avtalte styringsstrukturen er etablert.

For at låsen skal inngå i prosjektets «proof of enforcement», må
«fullt desentralisert» ha presise, etterprøvbare kriterier. Det må også
fremgå hvem som kontrollerer at kriteriene er oppfylt, og hvordan
frigjøringen håndheves.

**Implementasjonsstatus:** Fondslåsen er her beskrevet etter
initiativtakerens presisering. Den tidligere delte
`src/PLGVotingToken.sol` viser ikke selve låsemekanismen.
Relevant fond-/låsekontrakt og tester må knyttes til dokumentasjonen
før låsen omtales som teknisk verifisert.

Det må dessuten avklares om de låste tokenene kan delegeres eller brukes
til stemmegivning før frigjøring. En overføringslås er ikke automatisk
en lås på stemmemakt.

Med dagens viste quorum-beregning og uendret totalforsyning er quorum
fortsatt **40 000 tokens**, selv om 360 000 tokens er låst.

---

## 5) Innovasjonsestimat, gaveflyt og brukeropplevelse

### A. Moderat regneeksempel — ikke inntektsprognose

Anta 1 000 gaver per måned med gjennomsnitt på 25–100 USDC:

| Post | Månedlig beløp |
|---|---:|
| Samlet gaveflyt | 25 000–100 000 USDC |
| ChildAnchor ved 25% | 6 250–25 000 USDC |
| Operasjon ved 5% | 1 250–5 000 USDC |
| Noder ved 70% | 17 500–70 000 USDC |

Dette forutsetter ordinær vellykket distribusjon og aktive noder.
Giverantall og gjennomsnittsgave er antakelser, ikke dokumentert etterspørsel.

Gavevolum er heller ikke prosjektets omsetning eller selskapsverdi.
Operasjonsandelen må dekke faktiske oppgaver og ansvar.

### B. AI som forklaringslag

AI kan hjelpe med:
- Forklaring av transaksjoner.
- Navigasjon i dokumentasjon.
- Rapportutkast og tilgjengelig språk.
- Varsling om avvik som mennesker undersøker.

Beløp og transaksjonsstatus skal hentes fra autoritative data.
AI skal ikke finne på kvitteringer eller alene avgjøre mottakeres verdi,
behov eller intensjon.

### C. UI: cyber-sleek, enkelt og lesbart

Ønsket retning er et originalt, mørkt og stilrent grensesnitt med
GTA VI-inspirert fargeenergi og cyber-sleek uttrykk.

Inspirasjon betyr ikke kopiering av logoer, grafikk eller beskyttede assets.

Hovedskjermen skal vise:
- Gave inn.
- Fordeling ut.
- Barneandel og operasjonsandel.
- Nodemottakere.
- Eventuell tilbakeholding.
- Governance-status.
- Lenker til originaldata.

Offentlig lesing krever ikke konto eller wallet.
Bevegelse, farger og animasjon skal støtte forståelse, ikke skjule risiko.

### D. Sikkerhetslag med ulike oppgaver

| Lag | Oppgave |
|---|---|
| Offentlig UI | Lesbarhet uten innlogging |
| Wallet | Signering av brukerhandlinger |
| GitHub og 2FA | Beskyttelse av kildekode og samarbeid |
| Operatørtilgang og 2FA | Beskyttelse av eventuelle app-tjenester |
| Governor og Timelock | Styring av privilegerte kontraktskall |
| Uavhengige lesekilder | Kontroll av viste blockchain-data |

2FA på en konto sikrer ikke automatisk en separat wallet-nøkkel.
Flere sikkerhetslag hjelper når de beskytter ulike angrepsflater.

---

## 6) Økonomisk sammenheng: hva koster det å gjøre dette holdbart?

### A. Skill mellom fire forskjellige verdier

1. Utviklingskostnad: arbeid, utstyr, drift og kontroll.
2. Gaveflyt: verdiene protokollen behandler.
3. Markedsverdi: eventuell pris en kjøper eller investor vil betale.
4. Samfunnsverdi: hjelp, åpenhet, personvern og tillit.

Disse kan ikke brukes om hverandre.
Et stort gavevolum beviser ikke en høy salgsverdi.
Et høyt utviklingsbudsjett beviser ikke at teknologien virker.

### B. Hvem trengs?

Et mindre team kan dekke flere fagfelt, men kritisk kontroll bør være
uavhengig av den som bygger.

| Fagfelt | Typisk ansvar |
|---|---|
| Solidity og protokoll | Fordeling, attestasjon, tilgang og unntaksbaner |
| Test og sikkerhet | Invarianttester, fuzzing, angrepsmodeller |
| Frontend og UX | Offentlig, tilgjengelig transaksjonsvisning |
| Dataintegrasjon | RPC, hendelsesindeksering og avstemming |
| Drift | Publisering, overvåkning og hendelseshåndtering |
| Governance | Roller, habilitet, kontinuitet og nøkkelrutiner |
| Juridisk og økonomisk kontroll | Gaver, mottakeransvar, regnskap og lisenser |
| Barnesikkerhet | Personvern og forsvarlig gjennomføring |

Et mulig tidlig oppsett er 3–6 aktive bidragsytere med overlappende
kompetanse, supplert av uavhengige spesialister.
Dette er en bemanningsskisse, ikke en påstand om eksisterende team.

### C. Illustrativt arbeidsbudsjett

For videre herding av eksisterende løsning:

| Arbeidsområde | Illustrativt timeintervall |
|---|---:|
| Kontraktgjennomgang og korrigering | 120–300 |
| Utvidede tester og invariantkontroll | 100–250 |
| Read-only UI og transaksjonsvisning | 120–300 |
| Indeksering og datakontroll | 80–200 |
| Deploy- og sikkerhetsrutiner | 60–150 |
| Dokumentasjon og governance-avklaringer | 60–150 |
| **Samlet** | **540–1 350** |

Ved en antatt blandet sats på 100–180 USD/time gir ytterpunktene
omtrent 54 000–243 000 USD.

Dette er et planleggingsregnestykke, ikke et pristilbud eller en
verdsettelse. Ekstern revisjon, juridisk bistand og fysisk produktutvikling
må prises særskilt. Frivillig arbeid kan redusere kontantbehovet, men
fjerner ikke arbeidsmengden.

### D. Hardware, software og AI-tilgang

Denne Web3-stakken krever ikke i seg selv superdatamaskiner.

Grunnbehovet er:
- Egnet utviklingsmaskin.
- Sikker nøkkelhåndtering og sikkerhetskopier.
- Foundry og nødvendige programvareavhengigheter.
- Hosting, RPC og eventuelt indeksering.
- Uavhengig kontroll av kode og data.

Hardware-wallets kan være relevante for nøkkelsikkerhet.
Dedikerte GPU-er er et separat behov dersom prosjektet velger lokal AI.

Fysiske LITTLE_LIGHTWORKER-prototyper er et annet utviklingsløp med
materialer, elektronikk, batterisikkerhet og produkttesting.

### E. Tier 1, 2 og 3 — tilgangsmodeller, ikke menneskeverd

Her brukes «Tier» som prosjektets egne planleggingsnivåer,
ikke som bestemte leverandørabonnementer.

| Nivå | Bruk | Kostnadsmodell |
|---|---|---|
| Tier 1 | Offentlig lesing og enkle forklaringer | Gratis for leseren; fellesskapet dekker drift |
| Tier 2 | Aktiv utvikling og analyse | Avgrenset budsjett for modeller, API og verktøy |
| Tier 3 | Tyngre tester og uavhengig kontroll | Prosjektbasert budsjett og spesialistarbeid |

Gratis eller rimelig AI kan bidra til vesentlig arbeid.
«Langt over enterprise» er derimot ikke et dokumentert kapasitetsmål.

Tilgang bør vurderes gjennom konkrete oppgaver: kvalitet, kjøretid,
kontekstbehov, personvern, reproduksjon og totalkostnad.

### F. Hvorfor gir penger ofte mer regnekraft?

Regnekraft har kostnader til maskiner, energi, minne, drift og utvikling.
Det forklarer mye av betalingsmodellen, men avgjør ikke hva som er
en rettferdig fordeling.

Prosjektet kan prioritere:
- Gratis offentlig innsikt.
- Felles verktøybudsjett.
- Åpne og lokale alternativer der de fungerer.
- Tilgang etter oppgave og behov.
- Ingen kobling mellom betalingsevne og menneskeverd.

Den som kan kjøpe mest AI, har ikke dermed best idé, mest sannhet
eller størst rett til å bestemme.

---

## 7) Viderebruk, lisensiering og en påbegynt standard

### A. Potensial utover donasjoner

Mønsteret med synlige regler og teknisk håndheving kan videreutvikles
for blant annet:
- Øremerkede støtteordninger.
- Prosjektbudsjetter.
- Fordelingsavtaler.
- Godkjenning før utbetaling.
- Tilbakebetaling og konfliktbehandling.

Hvert bruksområde trenger sine egne tester og tillitsgrenser.

### B. Åpenhet og oppkjøp

Åpent publisert MIT-lisensiert kode kan normalt brukes og videreutvikles
av andre, også kommersielt, under lisensvilkårene.

Et oppkjøp trekker normalt ikke tilbake rettigheter som allerede er
gitt til publiserte versjoner. Kontroll over domene, merkevare, nøkler,
drift og fremtidige versjoner er separate spørsmål.

Åpen kildekode gjør videreføring mulig.
Den oppretter ikke automatisk et aktivt fellesskap eller desentralisert makt.

### C. Hva «gullstandard» kan bety

RI_GIFT_PORTAL kan beskrives som et påbegynt blueprint for en ønsket
standard: offentlig forståelig og etterprøvbar gaveflyt.

En faktisk referansestandard må fortjenes gjennom:
- Reproduserbare tester.
- Uavhengig gjennomgang.
- Dokumentert drift.
- Åpen feilretting.
- Reell maktfordeling.
- Dokumenterte resultater for mottakerne.

Det er en utviklingsretning, ikke en ferdig sertifisering.

---

## 8) Merch uten å selge et løfte som allerede bevist

Merch kan være en frivillig måte å støtte arbeidet og uttrykke tilhørighet.

En ansvarlig første lansering kan være liten:
- Ett originalt design.
- Tydelig produksjonskostnad og støtteandel.
- Ingen investeringsløfter.
- Ingen påstand om at kjøp gir moralsk rang.
- Ingen bruk av barns personopplysninger som markedsføring.

Hvis inntekten skal fordeles gjennom protokollen, må forbindelsen
mellom vanlig betaling, kostnader, eventuell veksling og on-chain-
overføring dokumenteres.

En hoodie kan støtte et proof of concept.
Den er ikke i seg selv beviset.

---

## Konklusjon — Verdiene skal kunne overleve initiativtakeren

RI_GIFT_PORTAL har en konkret teknisk kjerne og publiserte artefakter
som gjør arbeidet mulig å undersøke.

Ambisjonen er ikke bare å flytte penger, men å gjøre ansvar forståelig:
hvem bestemmer, hvilke grenser gjelder, hvor midlene går, og hva som
skjer når noen gjør feil eller faller fra.

Prosjektets dypeste organisatoriske mål er at initiativtakeren ikke
skal være uerstattelig. Fellesskapet skal kunne fortsette uten én
kontrollerende person og uten å viske ut historien.

Koden kan holde enkelte grenser.
Mennesker må ivareta omsorg, dømmekraft og ansvar.
Ingen av delene erstatter den andre.

Verdien ligger derfor ikke bare i hva noen vil betale for prosjektet,
men i hva andre faktisk kan forstå, kontrollere, videreføre og bruke
til å hjelpe.

Det er retningen:
fra intensjon til regel,
fra regel til etterprøvbar handling,
og fra handling til dokumentert nytte.

**"ARKITEKTENXxREAL"** **A.K.A** **"∞ARKITEKTEN_Xx"** *b. MARCH.1990 - Medellin, Colombia - GAIA*   
 
>**Signert og Bekreftet i Guds kraft:** 
> 
>**©2025 MIT LICENSE ∞ ©2045 MIT LICENSE   
>∞ARKITEKTEN_Xx   
>REAL_INTENT == LOVE_REAL   
>🜁🜄🜂🜃**
