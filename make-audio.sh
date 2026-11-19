#!/bin/bash
# ============================================================
#  Spelling Bee — make the word recordings (run on your Mac)
#  Records every spelling word in a natural UK female voice.
#  In Terminal, inside the spelling-bee folder, type:
#      bash make-audio.sh
#  or choose the voice yourself:  bash make-audio.sh "Kate (Enhanced)"
# ============================================================
cd "$(dirname "$0")" || exit 1
VOICE="$1"
if [ -z "$VOICE" ]; then
  for pref in "Serena (Premium)" "Kate (Premium)" "Stephanie (Premium)" "Martha (Premium)" \
              "Serena (Enhanced)" "Kate (Enhanced)" "Stephanie (Enhanced)" "Martha (Enhanced)"; do
    if say -v '?' | grep -F "$pref " | grep -q "en_GB"; then VOICE="$pref"; break; fi
  done
fi
if [ -z "$VOICE" ]; then
  echo ""
  echo "  No high-quality UK female voice is installed yet."
  echo "  Go to: System Settings > Accessibility > Spoken Content > System voice"
  echo "  > Manage Voices > English (United Kingdom), and download"
  echo "  Serena (Premium) or Kate (Enhanced). Then run this again."
  echo ""
  echo "  UK voices on this Mac right now:"
  say -v '?' | grep en_GB | sed 's/#.*//'
  exit 1
fi
echo ""
echo "  Recording with: $VOICE"
echo "  (this takes a few minutes — you can leave it running)"
mkdir -p audio
TMP="${TMPDIR:-/tmp}/sbclip.aiff"
n=0; made=0
while IFS=$'\t' read -r name text; do
  [ -z "$name" ] && continue
  n=$((n+1))
  out="audio/$name.m4a"
  if [ ! -s "$out" ]; then
    if say -v "$VOICE" -r 165 -o "$TMP" -- "$text" && afconvert -f m4af -d aac -b 64000 "$TMP" "$out"; then made=$((made+1)); fi
  fi
  if [ $((n % 25)) -eq 0 ]; then echo "  ... $n done"; fi
done <<'WORDS'
w-the	the
w-do	do
w-to	to
w-today	today
w-of	of
w-said	said
w-says	says
w-are	are
w-were	were
w-was	was
w-is	is
w-his	his
w-has	has
w-you	you
w-your	your
w-they	they
w-be	be
w-he	he
w-me	me
w-she	she
w-we	we
w-no	no
w-go	go
w-so	so
w-by	by
w-my	my
w-here	here
w-there	there
w-where	where
w-love	love
w-come	come
w-some	some
w-one	one
w-once	once
w-ask	ask
w-friend	friend
w-school	school
w-put	put
w-push	push
w-pull	pull
w-full	full
w-house	house
w-our	our
w-monday	Monday
w-tuesday	Tuesday
w-wednesday	Wednesday
w-thursday	Thursday
w-friday	Friday
w-saturday	Saturday
w-sunday	Sunday
w-because	because
w-door	door
w-floor	floor
w-poor	poor
w-find	find
w-kind	kind
w-mind	mind
w-behind	behind
w-child	child
w-children	children
w-wild	wild
w-climb	climb
w-most	most
w-only	only
w-both	both
w-cold	cold
w-gold	gold
w-hold	hold
w-told	told
w-every	every
w-everybody	everybody
w-even	even
w-great	great
w-break	break
w-steak	steak
w-pretty	pretty
w-beautiful	beautiful
w-after	after
w-fast	fast
w-last	last
w-past	past
w-father	father
w-class	class
w-grass	grass
w-pass	pass
w-plant	plant
w-path	path
w-bath	bath
w-hour	hour
w-move	move
w-prove	prove
w-improve	improve
w-sure	sure
w-sugar	sugar
w-eye	eye
w-could	could
w-should	should
w-would	would
w-who	who
w-whole	whole
w-any	any
w-many	many
w-clothes	clothes
w-busy	busy
w-people	people
w-water	water
w-again	again
w-half	half
w-money	money
w-parents	parents
w-accident	accident
w-accidentally	accidentally
w-actual	actual
w-actually	actually
w-address	address
w-answer	answer
w-appear	appear
w-arrive	arrive
w-believe	believe
w-bicycle	bicycle
w-breath	breath
w-breathe	breathe
w-build	build
w-business	business
w-calendar	calendar
w-caught	caught
w-centre	centre
w-century	century
w-certain	certain
w-circle	circle
w-complete	complete
w-consider	consider
w-continue	continue
w-decide	decide
w-describe	describe
w-different	different
w-difficult	difficult
w-disappear	disappear
w-early	early
w-earth	earth
w-eight	eight
w-eighth	eighth
w-enough	enough
w-exercise	exercise
w-experience	experience
w-experiment	experiment
w-extreme	extreme
w-famous	famous
w-favourite	favourite
w-february	February
w-forward	forward
w-forwards	forwards
w-fruit	fruit
w-grammar	grammar
w-group	group
w-guard	guard
w-guide	guide
w-heard	heard
w-heart	heart
w-height	height
w-history	history
w-imagine	imagine
w-increase	increase
w-important	important
w-interest	interest
w-island	island
w-knowledge	knowledge
w-learn	learn
w-length	length
w-library	library
w-material	material
w-medicine	medicine
w-mention	mention
w-minute	minute
w-natural	natural
w-naughty	naughty
w-notice	notice
w-occasion	occasion
w-occasionally	occasionally
w-often	often
w-opposite	opposite
w-ordinary	ordinary
w-particular	particular
w-peculiar	peculiar
w-perhaps	perhaps
w-popular	popular
w-position	position
w-possess	possess
w-possession	possession
w-possible	possible
w-potatoes	potatoes
w-pressure	pressure
w-probably	probably
w-promise	promise
w-purpose	purpose
w-quarter	quarter
w-question	question
w-recent	recent
w-regular	regular
w-reign	reign
w-remember	remember
w-sentence	sentence
w-separate	separate
w-special	special
w-straight	straight
w-strange	strange
w-strength	strength
w-suppose	suppose
w-surprise	surprise
w-therefore	therefore
w-though	though
w-although	although
w-thought	thought
w-through	through
w-various	various
w-weight	weight
w-woman	woman
w-women	women
w-accommodate	accommodate
w-accompany	accompany
w-according	according
w-achieve	achieve
w-aggressive	aggressive
w-amateur	amateur
w-ancient	ancient
w-apparent	apparent
w-appreciate	appreciate
w-attached	attached
w-available	available
w-average	average
w-awkward	awkward
w-bargain	bargain
w-bruise	bruise
w-category	category
w-cemetery	cemetery
w-committee	committee
w-communicate	communicate
w-community	community
w-competition	competition
w-conscience	conscience
w-conscious	conscious
w-controversy	controversy
w-convenience	convenience
w-correspond	correspond
w-criticise	criticise
w-curiosity	curiosity
w-definite	definite
w-desperate	desperate
w-determined	determined
w-develop	develop
w-dictionary	dictionary
w-disastrous	disastrous
w-embarrass	embarrass
w-environment	environment
w-equip	equip
w-equipped	equipped
w-equipment	equipment
w-especially	especially
w-exaggerate	exaggerate
w-excellent	excellent
w-existence	existence
w-explanation	explanation
w-familiar	familiar
w-foreign	foreign
w-forty	forty
w-frequently	frequently
w-government	government
w-guarantee	guarantee
w-harass	harass
w-hindrance	hindrance
w-identity	identity
w-immediate	immediate
w-immediately	immediately
w-individual	individual
w-interfere	interfere
w-interrupt	interrupt
w-language	language
w-leisure	leisure
w-lightning	lightning
w-marvellous	marvellous
w-mischievous	mischievous
w-muscle	muscle
w-necessary	necessary
w-neighbour	neighbour
w-nuisance	nuisance
w-occupy	occupy
w-occur	occur
w-opportunity	opportunity
w-parliament	parliament
w-persuade	persuade
w-physical	physical
w-prejudice	prejudice
w-privilege	privilege
w-profession	profession
w-programme	programme
w-pronunciation	pronunciation
w-queue	queue
w-recognise	recognise
w-recommend	recommend
w-relevant	relevant
w-restaurant	restaurant
w-rhyme	rhyme
w-rhythm	rhythm
w-sacrifice	sacrifice
w-secretary	secretary
w-shoulder	shoulder
w-signature	signature
w-sincere	sincere
w-sincerely	sincerely
w-soldier	soldier
w-stomach	stomach
w-sufficient	sufficient
w-suggest	suggest
w-symbol	symbol
w-system	system
w-temperature	temperature
w-thorough	thorough
w-twelfth	twelfth
w-variety	variety
w-vegetable	vegetable
w-vehicle	vehicle
w-yacht	yacht
s-there	Put the book over there.
ws-there	there. Put the book over there. there.
s-where	Where is my school bag?
ws-where	where. Where is my school bag? where.
s-our	This is our classroom.
ws-our	our. This is our classroom. our.
s-one	I have one sister.
ws-one	one. I have one sister. one.
s-hour	The lesson lasts one hour.
ws-hour	hour. The lesson lasts one hour. hour.
s-break	We play outside at break time.
ws-break	break. We play outside at break time. break.
s-steak	Dad cooked steak for dinner.
ws-steak	steak. Dad cooked steak for dinner. steak.
s-whole	She ate the whole apple.
ws-whole	whole. She ate the whole apple. whole.
s-great	We had a great day at the park.
ws-great	great. We had a great day at the park. great.
s-eye	I closed one eye.
ws-eye	eye. I closed one eye. eye.
s-who	Who is at the door?
ws-who	who. Who is at the door? who.
s-would	Would you like some water?
ws-would	would. Would you like some water? would.
s-heard	I heard a bird singing.
ws-heard	heard. I heard a bird singing. heard.
s-breath	Take a deep breath.
ws-breath	breath. Take a deep breath. breath.
s-breathe	Fish breathe through their gills.
ws-breathe	breathe. Fish breathe through their gills. breathe.
s-eight	A spider has eight legs.
ws-eight	eight. A spider has eight legs. eight.
s-reign	The king's reign lasted forty years.
ws-reign	reign. The king's reign lasted forty years. reign.
s-weight	Check the weight of the parcel.
ws-weight	weight. Check the weight of the parcel. weight.
s-though	It was windy, though it was sunny.
ws-though	though. It was windy, though it was sunny. though.
s-through	We walked through the forest.
ws-through	through. We walked through the forest. through.
s-thought	I thought carefully about my answer.
ws-thought	thought. I thought carefully about my answer. thought.
s-knowledge	Reading builds your knowledge.
ws-knowledge	knowledge. Reading builds your knowledge. knowledge.
s-guard	A guard stood at the gate.
ws-guard	guard. A guard stood at the gate. guard.
s-minute	Wait one minute, please.
ws-minute	minute. Wait one minute, please. minute.
s-programme	We watched a programme about the ocean.
ws-programme	programme. We watched a programme about the ocean. programme.
s-lightning	We saw lightning during the storm.
ws-lightning	lightning. We saw lightning during the storm. lightning.
s-queue	We stood in a queue for lunch.
ws-queue	queue. We stood in a queue for lunch. queue.
s-muscle	Exercise makes your muscles strong.
ws-muscle	muscle. Exercise makes your muscles strong. muscle.
s-yacht	The yacht sailed across the bay.
ws-yacht	yacht. The yacht sailed across the bay. yacht.
s-conscience	Her conscience told her to say sorry.
ws-conscience	conscience. Her conscience told her to say sorry. conscience.
s-conscious	He was conscious of everyone watching.
ws-conscious	conscious. He was conscious of everyone watching. conscious.
g-start	Hello! Let's practise your spellings!
p-1	Well done! That's right!
p-2	Fantastic spelling!
p-3	Brilliant! You got it!
p-4	Amazing! Keep going!
p-5	Yes! Super spelling!
p-6	Great job! You're a star!
p-7	Wonderful! Give yourself a big clap!
p-8	Excellent! You're a spelling superstar!
p-9	Perfect! Keep buzzing!
p-10	Hooray! You did it!
p-11	Beautiful spelling! Well done!
p-12	Spot on! I am so proud of you!
e-1	Good try! Let's practise this one again.
e-2	Nearly there! Have another look.
e-3	That's OK! Mistakes help us learn.
e-4	Keep going, you can do it!
e-5	Good effort! This one is a tricky word.
k-3	Three in a row! You're on fire!
k-5	Five in a row! Amazing!
k-8	Eight in a row! You're a spelling superstar!
k-10	Ten in a row! You're a champion bee!
perfect	Wow! A perfect score! Well done!
WORDS
rm -f "$TMP"
{
  printf '['
  first=1
  for f in audio/*.m4a; do
    [ -s "$f" ] || continue
    b=$(basename "$f" .m4a)
    if [ $first -eq 1 ]; then first=0; else printf ','; fi
    printf '"%s"' "$b"
  done
  printf ']\n'
} > audio/manifest.json
total=$(ls audio/*.m4a 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "  Done! $made new recordings made, $total in total."
echo "  Now open GitHub Desktop, commit and Push origin."
echo ""
