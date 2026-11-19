#!/bin/bash
# ============================================================
#  Spelling Bee — record Kate's voice (run on your Mac)
#  Fetches the latest word lists from the teacher page and records
#  any word or sentence that doesn't have a recording yet.
#  In Terminal, inside the spelling-bee folder, type:
#      bash make-audio.sh
#  or choose the voice yourself:  bash make-audio.sh "Kate (Enhanced)"
# ============================================================
cd "$(dirname "$0")" || exit 1
SUPABASE_URL="https://xpbkdnkfufkahaszfycd.supabase.co"
SUPABASE_KEY="sb_publishable_QIAV_9tLUBbDCu7FHqaTEw_zYQ0teEG"
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
  echo "  System Settings > Accessibility > Spoken Content > System voice"
  echo "  > Manage Voices > English (United Kingdom): download Kate (Enhanced)."
  exit 1
fi
LIST="${TMPDIR:-/tmp}/sb-list.tsv"
JSON="${TMPDIR:-/tmp}/sb-words.json"
# 1. phrases that never change (greeting, praise, encouragement)
cat > "$LIST" <<'FIXED'
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
FIXED
# 2. the latest word lists from the teacher page
echo ""
echo "  Getting the latest word lists…"
if curl -s -f -m 30 -X POST "$SUPABASE_URL/rest/v1/rpc/public_words" \
     -H "apikey: $SUPABASE_KEY" -H "Content-Type: application/json" -d '{}' -o "$JSON"; then
  osascript -l JavaScript -e '
    ObjC.import("Foundation");
    function run(argv){
      const s=$.NSString.stringWithContentsOfFileEncodingError(argv[0],4,null).js;
      const rows=JSON.parse(s), out=[], c=x=>String(x||"").replace(/[\t\r\n]+/g," ").trim();
      rows.forEach(r=>{ out.push(r.w_clip+"\t"+c(r.word));
        if(c(r.sentence)){ out.push(r.s_clip+"\t"+c(r.sentence)); out.push(r.ws_clip+"\t"+c(r.word)+". "+c(r.sentence)+" "+c(r.word)+"."); }
        if(c(r.meaning)&&r.m_clip){ out.push(r.m_clip+"\t"+c(r.meaning)); } });
      return out.join("\n");
    }' "$JSON" >> "$LIST" && echo "  Found $(grep -c '^w-' "$LIST") words."
else
  echo "  Couldn't reach the word lists (check the internet). Recording the fixed phrases only."
fi
echo "  Recording with: $VOICE"
mkdir -p audio
TMP="${TMPDIR:-/tmp}/sbclip.aiff"
n=0; made=0
while IFS=$'\t' read -r name text; do
  [ -z "$name" ] && continue
  out="audio/$name.m4a"
  if [ ! -s "$out" ]; then
    n=$((n+1))
    if say -v "$VOICE" -r 165 -o "$TMP" -- "$text" && afconvert -f m4af -d aac -b 64000 "$TMP" "$out"; then made=$((made+1)); fi
    if [ $((n % 25)) -eq 0 ]; then echo "  ... $n recorded"; fi
  fi
done < "$LIST"
rm -f "$TMP" "$JSON" "$LIST"
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
echo ""
if [ $made -eq 0 ]; then echo "  Everything already has Kate's voice — nothing new to record.";
else echo "  Done! $made new recording(s) made."; echo "  Now open GitHub Desktop, commit and Push origin."; fi
echo ""
