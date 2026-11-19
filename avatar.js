/* Spelling Bee avatars — shared drawing code (same as the student website) */
(function(){
const SKINS={s1:'#FFE3C8',s2:'#F7CBA2',s3:'#E3AB7A',s4:'#C68A5A',s5:'#99623B',s6:'#6B4428'};
const HAIRC={black:'#2A2230',dbrown:'#4A2E1F',brown:'#7A4A2A',blonde:'#EBC76E',auburn:'#9C4A2A','hc-blue':'#4F8DF5','hc-purple':'#9B6BE0','hc-pink':'#F28DBB','hc-green':'#45BF7E','hc-silver':'#CBD2DC'};
const BGS={honey:'#FFE7A0',sky:'#CFE8FF',mint:'#D4F2DF',pink:'#FBD9E6',lilac:'#E6DDFB'};
const ANIMALS={
 bee:{name:'Bee',c:'#FFD54A',d:'#2A2230'},bunny:{name:'Bunny',c:'#FFFFFF',d:'#F7B6C8'},kitten:{name:'Kitten',c:'#FFB45C',d:'#E8893A'},
 panda:{name:'Panda',c:'#FFFFFF',d:'#2F2F3A'},bear:{name:'Bear',c:'#B97A4E',d:'#8A5634'},fox:{name:'Fox',c:'#FF8A3D',d:'#3A2A22'},
 puppy:{name:'Puppy',c:'#F3D9B1',d:'#9A6A43'},owl:{name:'Owl',c:'#A9805C',d:'#7A5636'},penguin:{name:'Penguin',c:'#2F3A56',d:'#2F3A56'},
 frog:{name:'Frog',c:'#7ED87E',d:'#4FAF59'},lion:{name:'Lion',c:'#FFCB57',d:'#E58A2E'},koala:{name:'Koala',c:'#B8C0CC',d:'#8C96A6'},
 unicorn:{name:'Unicorn',c:'#FFFFFF',d:'#F2A7D0'},
 zib:{name:'Alien Zib',c:'#9BE58A',d:'#5DBB63'},pip:{name:'Alien Pip',c:'#C9A7F5',d:'#9B6BE0'},blu:{name:'Alien Blu',c:'#8FD3F5',d:'#3FA3D8'}};
const PEOPLE={
 princess:{name:'Princess',hair:'wavy',hc:'brown',skin:'s2'},snowpr:{name:'Snow princess',hair:'long',hc:'dbrown',skin:'s1'},
 fairy:{name:'Fairy',hair:'bob',hc:'blonde',skin:'s3'},mermaid:{name:'Mermaid',hair:'vlong',hc:'dbrown',skin:'s4'},
 ballerina:{name:'Ballerina',hair:'bun',hc:'black',skin:'s5'},prince:{name:'Prince',hair:'short',hc:'black',skin:'s3'},
 knight:{name:'Knight',hair:'short',hc:'brown',skin:'s2'},pirate:{name:'Pirate captain',hair:'curly',hc:'dbrown',skin:'s4'},
 astro:{name:'Astronaut',hair:'short',hc:'black',skin:'s6'}};
const AV_DEFAULT={char:'bee',bg:'honey',skin:'',hairc:'',eyes:'big',mouth:'smile',blush:'yes',top:'none',hat:'none',acc:'none',back:'none',pet:'none',medal:'none'};
const AV_PARTS=[
 {k:'char',tab:'char',label:'Choose your character',opts:[...Object.keys(ANIMALS).map(id=>({id,name:ANIMALS[id].name})),...Object.keys(PEOPLE).map(id=>({id,name:PEOPLE[id].name}))]},
 {k:'skin',tab:'look',label:'Skin',people:1,opts:Object.keys(SKINS).map(id=>({id}))},
 {k:'hairc',tab:'look',label:'Hair colour',people:1,opts:[{id:'black'},{id:'dbrown'},{id:'brown'},{id:'blonde'},{id:'auburn'},{id:'hc-blue',name:'Blue',price:20},{id:'hc-purple',name:'Purple',price:20},{id:'hc-pink',name:'Pink',price:20},{id:'hc-green',name:'Green',price:30},{id:'hc-silver',name:'Silver',price:40}]},
 {k:'eyes',tab:'look',label:'Eyes',opts:[{id:'big',name:'Sparkly'},{id:'happy',name:'Happy'},{id:'wink',name:'Wink'}]},
 {k:'mouth',tab:'look',label:'Smile',opts:[{id:'smile',name:'Smile'},{id:'open',name:'Big smile'}]},
 {k:'blush',tab:'look',label:'Rosy cheeks',opts:[{id:'yes',name:'Yes'},{id:'no',name:'No'}]},
 {k:'top',tab:'clothes',label:'Clothes',opts:[{id:'none',name:'My outfit'},{id:'tee-honey',name:'Honey tee'},{id:'tee-blue',name:'Blue tee'},{id:'tee-green',name:'Green tee'},{id:'tee-red',name:'Red tee'},
   {id:'top-stripes',name:'Stripy top',price:10},{id:'top-hoodie',name:'Hoodie',price:15},{id:'top-school',name:'School jumper',price:15},{id:'top-football',name:'Football kit',price:20},{id:'top-dress',name:'Party dress',price:20},{id:'top-labcoat',name:'Lab coat',price:30},{id:'top-superhero',name:'Super suit',price:30},
   {id:'top-gown',name:'Ball gown',price:40},{id:'top-prince',name:'Prince jacket',price:40},{id:'top-cloak',name:'Winter cloak',price:45},{id:'top-armour',name:'Knight armour',price:50}]},
 {k:'hat',tab:'hats',label:'Hats & crowns',opts:[{id:'none',name:'None'},{id:'hijab-pink',name:'Pink hijab',people:1},{id:'hijab-navy',name:'Navy hijab',people:1},{id:'hijab-lilac',name:'Lilac hijab',people:1},{id:'hijab-cream',name:'Cream hijab',people:1},{id:'hat-bow',name:'Hair bow',price:20},{id:'hat-cap',name:'Cap',price:25},{id:'hat-beanie',name:'Beanie',price:25},{id:'hat-party',name:'Party hat',price:30},{id:'hat-chef',name:'Chef hat',price:35},{id:'hat-tiara',name:'Tiara',price:40},{id:'hat-pirate',name:'Pirate hat',price:40},{id:'hat-explorer',name:'Explorer hat',price:40},{id:'hat-wizard',name:'Wizard hat',price:50},{id:'hat-helmet',name:'Knight helmet',price:60},{id:'hat-flowers',name:'Flower crown',price:0,need:'secure20'},{id:'hat-crown',name:'Golden crown',price:300}]},
 {k:'acc',tab:'extras',label:'Things to hold & wear',opts:[{id:'none',name:'None'},{id:'acc-glasses',name:'Glasses',price:30},{id:'acc-bowtie',name:'Bow tie',price:30},{id:'acc-necklace',name:'Pearl necklace',price:35},{id:'acc-sunglasses',name:'Sunglasses',price:40},{id:'acc-backpack',name:'Backpack',price:45},{id:'acc-wand',name:'Magic wand',price:50},{id:'acc-sword',name:'Sword',price:50},{id:'acc-shield',name:'Shield',price:50},{id:'acc-headphones',name:'Headphones',price:50},{id:'acc-pencil',name:'Magic pencil',price:60}]},
 {k:'back',tab:'extras',label:'Special',opts:[{id:'none',name:'None'},{id:'back-cape',name:'Royal cape',price:80},{id:'back-fairy',name:'Fairy wings',price:120},{id:'back-wings',name:'Bee wings',price:150},{id:'back-jetpack',name:'Honey jet-pack',price:150}]},
 {k:'pet',tab:'extras',label:'Pets',opts:[{id:'none',name:'None'},{id:'pet-bee',name:'Pet bee',price:100},{id:'pet-cat',name:'Pet kitten',price:120}]},
 {k:'medal',tab:'extras',label:'Medals',opts:[{id:'none',name:'None'},{id:'medal-trophy',name:'Race trophy',price:0,need:'race1'},{id:'medal-champ',name:'Champion medal',price:250}]},
 {k:'bg',tab:'bg',label:'Background',opts:[{id:'honey'},{id:'sky'},{id:'mint'},{id:'pink'},{id:'lilac'},{id:'bg-garden',name:'Garden',price:60},{id:'bg-castle',name:'Castle',price:60},{id:'bg-beach',name:'Beach',price:60},{id:'bg-space',name:'Space',price:60},{id:'bg-library',name:'Library',price:60}]}];
const AV_TABS=[['char','🐾 Character'],['look','😊 Look'],['clothes','👕 Clothes'],['hats','👑 Hats'],['extras','✨ Extras'],['bg','🖼️ Background']];
const NEEDS={secure20:'Unlock by making 20 words secure 🔵',race1:'Unlock by winning a race against a friend 🏆'};
function avOpt(id){for(const p of AV_PARTS){const o=p.opts.find(o=>o.id===id);if(o)return Object.assign({k:p.k},o)}return null}
function isShopItem(id){const o=avOpt(id);return !!o&&(o.price>0||!!o.need)}
function avOf(a){const r=Object.assign({},AV_DEFAULT,(a&&typeof a==='object')?a:{});if(!ANIMALS[r.char]&&!PEOPLE[r.char])r.char='bee';return r}
const OL='stroke="#3B2F2F" stroke-width="2.2"';
function faceKit(a,kind,eyeY,ex1,ex2,my){let o='';const pandaE=kind==='panda';
 if(a.eyes==='happy')o+=`<path d="M${ex1-6} ${eyeY+2} Q${ex1} ${eyeY-6} ${ex1+6} ${eyeY+2} M${ex2-6} ${eyeY+2} Q${ex2} ${eyeY-6} ${ex2+6} ${eyeY+2}" fill="none" stroke="${pandaE?'#fff':'#2A2230'}" stroke-width="3.5" stroke-linecap="round"/>`;
 else if(a.eyes==='wink')o+=`<ellipse cx="${ex1}" cy="${eyeY}" rx="5.5" ry="6.5" fill="#2A2230"/><circle cx="${ex1+2}" cy="${eyeY-2.5}" r="2.2" fill="#fff"/><path d="M${ex2-6} ${eyeY} Q${ex2} ${eyeY+5} ${ex2+6} ${eyeY}" fill="none" stroke="${pandaE?'#fff':'#2A2230'}" stroke-width="3.5" stroke-linecap="round"/>`;
 else o+=[ex1,ex2].map(x=>`<ellipse cx="${x}" cy="${eyeY}" rx="5.5" ry="6.5" fill="#2A2230"${pandaE?' stroke="#fff" stroke-width="1.5"':''}/><circle cx="${x+2}" cy="${eyeY-2.5}" r="2.4" fill="#fff"/><circle cx="${x-2}" cy="${eyeY+2.5}" r="1" fill="#fff"/>`).join('');
 const beak=kind==='owl'||kind==='penguin';
 if(beak)o+=`<path d="M55 68 L65 68 L60 76 Z" fill="#FFA62B" stroke="#3B2F2F" stroke-width="1.5" stroke-linejoin="round"/>`;
 else if(ANIMALS[kind]&&!['koala','zib','pip','blu'].includes(kind))o+=`<ellipse cx="60" cy="${my-4}" rx="4" ry="3" fill="${['bunny','kitten','unicorn'].includes(kind)?'#F48FA8':'#3B2F2F'}"/>`;
 if(!beak){if(a.mouth==='open')o+=`<path d="M53 ${my} Q60 ${my+10} 67 ${my} Z" fill="#B23A48"/><path d="M56 ${my+4} Q60 ${my+8} 64 ${my+4}" fill="#F48FA8"/>`;
  else o+=PEOPLE[kind]?`<path d="M54 ${my} Q60 ${my+6} 66 ${my}" fill="none" stroke="#7A2E3A" stroke-width="2.6" stroke-linecap="round"/>`:`<path d="M53 ${my} Q56.5 ${my+4} 60 ${my} Q63.5 ${my+4} 67 ${my}" fill="none" stroke="#3B2F2F" stroke-width="2.4" stroke-linecap="round"/>`}
 if(kind==='kitten')o+=`<path d="M28 68 H40 M28 74 H40 M80 68 H92 M80 74 H92" stroke="#3B2F2F" stroke-width="1.6" stroke-linecap="round"/>`;
 if(a.blush!=='no'){const by=kind==='frog'?62:PEOPLE[kind]?70:72,bx=kind==='frog'?34:PEOPLE[kind]?38:36;o+=`<ellipse cx="${bx}" cy="${by}" rx="6" ry="3.5" fill="#FF8FA3" opacity=".55"/><ellipse cx="${120-bx}" cy="${by}" rx="6" ry="3.5" fill="#FF8FA3" opacity=".55"/>`}
 return o}
function animalHead(kind,a){const A=ANIMALS[kind],c=A.c,d=A.d;let o='';
 if(kind==='bunny')o+=`<ellipse cx="44" cy="22" rx="9" ry="22" fill="${c}" ${OL}/><ellipse cx="76" cy="22" rx="9" ry="22" fill="${c}" ${OL}/><ellipse cx="44" cy="24" rx="4.5" ry="15" fill="${d}"/><ellipse cx="76" cy="24" rx="4.5" ry="15" fill="${d}"/>`;
 if(kind==='kitten'||kind==='fox')o+=`<path d="M30 46 L34 14 L54 32 Z" fill="${c}" ${OL} stroke-linejoin="round"/><path d="M90 46 L86 14 L66 32 Z" fill="${c}" ${OL} stroke-linejoin="round"/><path d="M36 38 L37 22 L48 32 Z" fill="${kind==='fox'?d:'#FFC9D6'}"/><path d="M84 38 L83 22 L72 32 Z" fill="${kind==='fox'?d:'#FFC9D6'}"/>`;
 if(kind==='panda'||kind==='bear')o+=`<circle cx="34" cy="30" r="12" fill="${d}" ${OL}/><circle cx="86" cy="30" r="12" fill="${d}" ${OL}/>${kind==='bear'?`<circle cx="34" cy="30" r="6" fill="#E9B98F"/><circle cx="86" cy="30" r="6" fill="#E9B98F"/>`:''}`;
 if(kind==='koala')o+=`<circle cx="28" cy="38" r="16" fill="${c}" ${OL}/><circle cx="92" cy="38" r="16" fill="${c}" ${OL}/><circle cx="28" cy="38" r="9" fill="#F3E6EC"/><circle cx="92" cy="38" r="9" fill="#F3E6EC"/>`;
 if(kind==='lion'){o+=[...Array(14)].map((_,i)=>{const t=i/14*Math.PI*2;return `<circle cx="${(60+Math.cos(t)*36).toFixed(1)}" cy="${(58+Math.sin(t)*36).toFixed(1)}" r="13" fill="${d}"/>`}).join('');o+=`<circle cx="38" cy="32" r="7" fill="${c}" ${OL}/><circle cx="82" cy="32" r="7" fill="${c}" ${OL}/>`}
 if(kind==='bee')o+=`<path d="M48 30 Q42 12 34 10" fill="none" stroke="${d}" stroke-width="3" stroke-linecap="round"/><path d="M72 30 Q78 12 86 10" fill="none" stroke="${d}" stroke-width="3" stroke-linecap="round"/><circle cx="34" cy="10" r="5" fill="${d}"/><circle cx="86" cy="10" r="5" fill="${d}"/>`;
 if(kind==='owl')o+=`<path d="M30 40 L32 16 L48 30 Z" fill="${d}" ${OL} stroke-linejoin="round"/><path d="M90 40 L88 16 L72 30 Z" fill="${d}" ${OL} stroke-linejoin="round"/>`;
 if(kind==='frog')o+=`<circle cx="42" cy="34" r="14" fill="${c}" ${OL}/><circle cx="78" cy="34" r="14" fill="${c}" ${OL}/>`;
 if(kind==='unicorn')o+=`<path d="M36 40 L38 18 L52 30 Z" fill="${c}" ${OL} stroke-linejoin="round"/><path d="M84 40 L82 18 L68 30 Z" fill="${c}" ${OL} stroke-linejoin="round"/>`;
 if(kind==='zib')o+=`<path d="M46 32 L40 10" stroke="#3B2F2F" stroke-width="2.5"/><path d="M74 32 L80 10" stroke="#3B2F2F" stroke-width="2.5"/><circle cx="40" cy="9" r="6" fill="#FFD54A" ${OL}/><circle cx="80" cy="9" r="6" fill="#FFD54A" ${OL}/>`;
 if(kind==='pip')o+=`${[[40,30,-25],[60,22,0],[80,30,25]].map(([x,y,r])=>`<path d="M${x-6} ${y+8} Q${x} ${y-14} ${x+6} ${y+8}Z" fill="${d}" ${OL} transform="rotate(${r} ${x} ${y})"/>`).join('')}`;
 if(kind==='blu')o+=`<ellipse cx="22" cy="58" rx="12" ry="7" transform="rotate(-20 22 58)" fill="${c}" ${OL}/><ellipse cx="98" cy="58" rx="12" ry="7" transform="rotate(20 98 58)" fill="${c}" ${OL}/><path d="M60 28 Q54 14 62 10 Q60 18 68 20 Q62 22 60 28Z" fill="${d}" ${OL}/>`;
 o+=`<ellipse cx="60" cy="60" rx="36" ry="33" fill="${c}" ${OL}/>`;
 if(kind==='zib')o+=`<circle cx="40" cy="44" r="3" fill="${d}"/><circle cx="82" cy="48" r="4" fill="${d}"/><circle cx="76" cy="38" r="2.5" fill="${d}"/>`;
 if(kind==='pip')o+=`<circle cx="36" cy="50" r="3.5" fill="#fff" opacity=".6"/><circle cx="84" cy="46" r="2.5" fill="#fff" opacity=".6"/>`;
 if(kind==='blu')o+=`<path d="M40 44 l1.5 3 3 .5 -2.2 2 .5 3 -2.8 -1.5 -2.8 1.5 .5 -3 -2.2 -2 3 -.5z" fill="#fff" opacity=".7"/>`;
 if(kind==='unicorn')o+=`<path d="M54 30 L60 2 L66 30 Z" fill="#FFD54A" ${OL} stroke-linejoin="round"/><path d="M56 22 L64 18 M57 14 L63 11" stroke="#E0A800" stroke-width="2"/><path d="M30 44 Q36 24 56 30 Q44 34 42 50 Q36 44 30 44Z" fill="#F2A7D0" ${OL}/><path d="M24 54 Q24 40 34 40 Q30 50 34 60 Q26 60 24 54Z" fill="#C7A7F0" ${OL}/>`;
 if(kind==='panda')o+=`<ellipse cx="46" cy="60" rx="10" ry="12" transform="rotate(-20 46 60)" fill="${d}"/><ellipse cx="74" cy="60" rx="10" ry="12" transform="rotate(20 74 60)" fill="${d}"/>`;
 if(kind==='fox')o+=`<path d="M26 66 Q40 92 60 78 Q80 92 94 66 Q78 76 60 70 Q42 76 26 66Z" fill="#fff"/>`;
 if(kind==='bear'||kind==='puppy')o+=`<ellipse cx="60" cy="74" rx="15" ry="11" fill="${kind==='bear'?'#E9B98F':'#FFF4E2'}"/>`;
 if(kind==='puppy')o+=`<path d="M28 44 Q14 50 18 76 Q26 82 32 70 Z" fill="${d}" ${OL}/><path d="M92 44 Q106 50 102 76 Q94 82 88 70 Z" fill="${d}" ${OL}/>`;
 if(kind==='penguin')o+=`<path d="M60 44 Q72 32 84 48 Q92 66 80 82 Q60 96 40 82 Q28 66 36 48 Q48 32 60 44Z" fill="#fff"/>`;
 if(kind==='owl')o+=`<circle cx="46" cy="60" r="13" fill="#F6E7CF"/><circle cx="74" cy="60" r="13" fill="#F6E7CF"/>`;
 if(kind==='koala')o+=`<ellipse cx="60" cy="70" rx="8" ry="11" fill="#4A4458"/>`;
 const fr=kind==='frog';o+=faceKit(a,kind,fr?36:60,fr?42:46,fr?78:74,fr?66:72);return o}
function hairBack(st,hc){if(st==='wavy')return `<path d="M26 56 C22 30 98 30 94 56 L98 100 Q90 108 84 100 Q78 110 70 100 L50 100 Q42 110 36 100 Q30 108 22 100 Z" fill="${hc}" ${OL}/>`;
 if(st==='long')return `<path d="M27 56 C24 28 96 28 93 56 L96 104 H24 Z" fill="${hc}" ${OL}/>`;
 if(st==='vlong')return `<path d="M26 56 C22 28 98 28 94 56 Q100 90 92 124 H28 Q20 90 26 56Z" fill="${hc}" ${OL}/>`;
 if(st==='bob')return `<path d="M27 58 C24 28 96 28 93 58 L94 84 Q60 92 26 84 Z" fill="${hc}" ${OL}/>`;
 if(st==='bun')return `<circle cx="60" cy="22" r="13" fill="${hc}" ${OL}/>`;
 if(st==='curly')return [[30,48],[34,34],[46,26],[60,23],[74,26],[86,34],[90,48]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="11" fill="${hc}" ${OL}/>`).join('');
 return ''}
function hairFront(st,hc){if(st==='curly')return [[38,36],[50,30],[62,29],[74,31],[84,38]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="9" fill="${hc}"/>`).join('');
 if(st==='short')return `<path d="M29 56 C26 26 94 26 91 56 C86 42 76 38 62 40 C54 34 40 38 29 56Z" fill="${hc}" ${OL}/>`;
 return `<path d="M28 58 C26 26 94 26 92 58 C88 44 80 40 72 42 Q66 34 58 42 Q46 38 40 44 C34 46 30 52 28 58Z" fill="${hc}" ${OL}/>`}
const HIJABS={'hijab-pink':'#F4A6C4','hijab-navy':'#2E4A86','hijab-lilac':'#B9A2E8','hijab-cream':'#F3E6CC'};
function personHead(kind,a){const P=PEOPLE[kind];const skin=SKINS[a.skin]||SKINS[P.skin],hc=HAIRC[a.hairc]||HAIRC[P.hc];let o='';const hj=HIJABS[a.hat];
 if(hj)o+=`<path d="M22 62 C20 20 100 20 98 62 Q102 96 90 110 H30 Q18 96 22 62Z" fill="${hj}" ${OL}/>`;
 else{o+=hairBack(P.hair,hc);o+=`<ellipse cx="29" cy="62" rx="5" ry="7" fill="${skin}" ${OL}/><ellipse cx="91" cy="62" rx="5" ry="7" fill="${skin}" ${OL}/>`}
 o+=`<ellipse cx="60" cy="60" rx="31" ry="30" fill="${skin}" ${OL}/>`;
 if(hj)o+=`<path d="M29 62 C27 28 93 28 91 62 C88 44 76 37 60 37 C44 37 32 44 29 62Z" fill="${hj}" ${OL}/><path d="M34 46 C42 36 78 36 86 46" fill="none" stroke="rgba(255,255,255,.45)" stroke-width="2"/>`;
 else o+=hairFront(P.hair,hc);
 o+=faceKit(a,kind,62,47,73,73);
 if(a.hat==='none'){
  if(kind==='princess')o+=`<path d="M44 34 L46 22 L52 29 L60 18 L68 29 L74 22 L76 34 Z" fill="#FFD54A" ${OL} stroke-linejoin="round"/><circle cx="60" cy="27" r="2.5" fill="#F472B6"/>`;
  if(kind==='snowpr')o+=`<path d="M40 36 Q60 26 80 36" fill="none" stroke="#9CC9F0" stroke-width="4"/>${[[48,30],[60,24],[72,30]].map(([x,y])=>`<g transform="translate(${x} ${y})" stroke="#7FB3F5" stroke-width="2" stroke-linecap="round"><path d="M0 -6 V6 M-5 -3 L5 3 M-5 3 L5 -3"/></g>`).join('')}`;
  if(kind==='fairy')o+=`<g transform="translate(80 34)"><circle cx="0" cy="-6" r="5" fill="#F9A8D4"/><circle cx="6" cy="0" r="5" fill="#F9A8D4"/><circle cx="0" cy="6" r="5" fill="#F9A8D4"/><circle cx="-6" cy="0" r="5" fill="#F9A8D4"/><circle r="3.5" fill="#FFD54A"/></g>`;
  if(kind==='mermaid')o+=`<path d="M80 30 l2.5 5.5 6 .5 -4.5 4 1.5 6 -5.5 -3 -5.5 3 1.5 -6 -4.5 -4 6 -.5z" fill="#FF9F7A" stroke="#E0784F" stroke-width="1.2"/>`;
  if(kind==='ballerina')o+=`<path d="M48 22 Q60 30 72 22" fill="none" stroke="#F9A8D4" stroke-width="4" stroke-linecap="round"/>`;
  if(kind==='prince')o+=`<path d="M46 34 L46 22 L53 28 L60 18 L67 28 L74 22 L74 34 Z" fill="#FFD54A" ${OL} stroke-linejoin="round"/><circle cx="60" cy="29" r="2.5" fill="#3D7DD8"/>`;
  if(kind==='pirate')o+=`<path d="M28 46 C30 22 90 22 92 46 Z" fill="#D62839" ${OL}/>${[[40,36],[56,30],[72,32],[84,40]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="2" fill="#fff"/>`).join('')}<path d="M90 42 l10 4 -6 6 Z" fill="#D62839" ${OL}/>`;
 }
 return o}
function outfit(kind,a,id){const body=(c,extra)=>`<path d="M26 124 C26 100 40 90 60 90 C80 90 94 100 94 124Z" fill="${c}" ${OL}/>`+(extra||'');let t=a.top;
 const tees={'tee-honey':'#F5B700','tee-blue':'#4F8DF5','tee-green':'#3DBB76','tee-red':'#E25555'};
 if(t==='none'){const own={princess:'top-gown',snowpr:'top-cloak',fairy:'own-fairy',mermaid:'own-mermaid',ballerina:'own-ballet',prince:'top-prince',knight:'top-armour',pirate:'own-pirate',astro:'own-astro'}[kind];
  if(own)t=own;else{const A=ANIMALS[kind]||ANIMALS.bee;return kind==='bee'?`<clipPath id="${id}b"><path d="M26 124 C26 100 40 90 60 90 C80 90 94 100 94 124Z"/></clipPath>`+body(A.c)+`<g clip-path="url(#${id}b)"><rect x="0" y="102" width="120" height="7" fill="#2A2230"/><rect x="0" y="115" width="120" height="7" fill="#2A2230"/></g>`:kind==='penguin'?body(A.c,`<path d="M48 96 Q60 90 72 96 L74 124 H46 Z" fill="#fff"/>`):kind==='unicorn'?body('#fff'):body(A.c)}}
 if(tees[t])return body(tees[t],`<path d="M50 91 Q60 99 70 91" fill="none" stroke="rgba(0,0,0,.2)" stroke-width="2"/>`);
 if(t==='top-stripes')return `<clipPath id="${id}c"><path d="M26 124 C26 100 40 90 60 90 C80 90 94 100 94 124Z"/></clipPath>`+body('#fff')+`<g clip-path="url(#${id}c)">${[96,104,112,120].map(y=>`<rect x="0" y="${y}" width="120" height="4" fill="#22386B"/>`).join('')}</g>`;
 if(t==='top-hoodie')return body('#8A55D6',`<path d="M46 92 Q60 104 74 92" fill="#7442BE"/><line x1="55" y1="98" x2="55" y2="110" stroke="#fff" stroke-width="2"/><line x1="65" y1="98" x2="65" y2="110" stroke="#fff" stroke-width="2"/>`);
 if(t==='top-school')return body('#22386B',`<path d="M50 90 L60 102 L70 90 Z" fill="#fff"/><path d="M58 98 L62 98 L64 118 L60 122 L56 118 Z" fill="#D62839"/>`);
 if(t==='top-football')return body('#2FA35A',`<rect x="26" y="112" width="68" height="4" fill="#fff"/><text x="60" y="111" font-size="14" font-weight="bold" text-anchor="middle" fill="#fff" font-family="Arial">1</text>`);
 if(t==='top-dress')return `<path d="M42 92 Q60 86 78 92 L98 124 H22 Z" fill="#F07AB0" ${OL}/>${[34,48,62,76,90].map(x=>`<circle cx="${x}" cy="118" r="2" fill="#fff"/>`).join('')}`;
 if(t==='top-labcoat')return body('#FFFFFF',`<path d="M52 90 L60 112 L68 90 Z" fill="#4F8DF5"/>`);
 if(t==='top-superhero')return body('#2F6FE4',`<path d="M60 98 l3.5 7 7.5 1 -5.5 5 1.5 7.5 -7 -3.5 -7 3.5 1.5 -7.5 -5.5 -5 7.5 -1z" fill="#FFD54A"/>`);
 if(t==='top-gown')return `<path d="M40 92 Q60 86 80 92 L100 124 H20 Z" fill="#F7A8CF" ${OL}/><path d="M42 100 Q60 108 78 100" fill="none" stroke="#fff" stroke-width="2.5"/>${[[36,116],[52,112],[68,112],[84,116],[60,120]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="1.8" fill="#fff"/>`).join('')}`;
 if(t==='top-cloak')return body('#C7B8F2',`<path d="M38 94 Q60 104 82 94" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round"/><g transform="translate(60 112)" stroke="#fff" stroke-width="2" stroke-linecap="round"><path d="M0 -6 V6 M-5 -3 L5 3 M-5 3 L5 -3"/></g>`);
 if(t==='top-prince')return body('#22386B',`<path d="M42 94 L80 120" stroke="#D62839" stroke-width="6"/>${[100,108,116].map(y=>`<circle cx="52" cy="${y}" r="2.2" fill="#FFD54A"/>`).join('')}<path d="M34 98 h10 M76 98 h10" stroke="#FFD54A" stroke-width="3"/>`);
 if(t==='top-armour')return body('#B8C2D0',`<path d="M60 92 V124" stroke="#8792A4" stroke-width="2"/><path d="M40 104 Q60 110 80 104" fill="none" stroke="#8792A4" stroke-width="2"/><circle cx="60" cy="112" r="5" fill="#D62839" ${OL}/>`);
 if(t==='own-fairy')return `<path d="M42 92 Q60 86 78 92 L94 124 H26 Z" fill="#8BD9A6" ${OL}/>${[[34,124],[48,124],[62,124],[76,124],[90,124]].map(([x])=>`<path d="M${x-7} 124 L${x} 114 L${x+7} 124Z" fill="#6CC48C"/>`).join('')}`;
 if(t==='own-mermaid')return body('#2BB5A8',`<path d="M40 100 Q48 94 56 100 Q48 106 40 100 Z M64 100 Q72 94 80 100 Q72 106 64 100Z" fill="#A6F0E4" ${OL}/>${[44,52,60,68,76].map(x=>`<circle cx="${x}" cy="92" r="2.4" fill="#fff" stroke="#ddd"/>`).join('')}`);
 if(t==='own-ballet')return body('#F9A8D4',`<path d="M20 112 Q60 100 100 112 L104 124 H16 Z" fill="#FBCFE8" ${OL}/>`);
 if(t==='own-pirate')return `<clipPath id="${id}p"><path d="M26 124 C26 100 40 90 60 90 C80 90 94 100 94 124Z"/></clipPath>`+body('#fff')+`<g clip-path="url(#${id}p)">${[98,108,118].map(y=>`<rect x="0" y="${y}" width="120" height="4" fill="#D62839"/>`).join('')}</g><path d="M30 104 L44 94 V124 H30Z M90 104 L76 94 V124 H90Z" fill="#3A2A55"/>`;
 if(t==='own-astro')return body('#F4F6FA',`<rect x="48" y="102" width="24" height="14" rx="3" fill="#4F8DF5" ${OL}/><circle cx="54" cy="109" r="2" fill="#D62839"/><circle cx="62" cy="109" r="2" fill="#FFD54A"/>`);
 return body('#F5B700')}
let AVN=0;
function avatarSVG(a0,size,round){const a=avOf(a0);const id='av'+(++AVN);const kind=a.char;let o='';
 const bgc=BGS[a.bg];
 if(bgc)o+=`<rect width="120" height="120" fill="${bgc}"/>`;
 else if(a.bg==='bg-garden')o+=`<rect width="120" height="120" fill="#BFE6FF"/><circle cx="100" cy="18" r="9" fill="#FFD54A"/><path d="M0 84 Q30 70 60 82 T120 78 V120 H0Z" fill="#7CC47F"/>${[[10,92,'#F472B6'],[22,104,'#FFD54A'],[104,100,'#F472B6'],[112,88,'#FFFFFF']].map(([x,y,c])=>`<circle cx="${x}" cy="${y}" r="4" fill="${c}"/><circle cx="${x}" cy="${y}" r="1.6" fill="#F59E0B"/>`).join('')}`;
 else if(a.bg==='bg-castle')o+=`<rect width="120" height="120" fill="#E6DDFB"/><path d="M6 100 V54 h8 v-6 h4 v6 h6 v-6 h4 v6 h8 V100Z M84 100 V54 h8 v-6 h4 v6 h6 v-6 h4 v6 h8 V100Z" fill="#F5D0E6"/><path d="M6 54 l14 -18 l14 18Z M84 54 l14 -18 l14 18Z" fill="#B48BE6"/><rect y="100" width="120" height="20" fill="#A5D6A7"/>`;
 else if(a.bg==='bg-beach')o+=`<rect width="120" height="120" fill="#BDE7FF"/><circle cx="20" cy="20" r="11" fill="#FFD54A"/><rect y="70" width="120" height="22" fill="#4FB3E8"/><rect y="92" width="120" height="28" fill="#F4D79B"/>`;
 else if(a.bg==='bg-space')o+=`<rect width="120" height="120" fill="#1C2550"/>${[[12,14],[30,40],[100,16],[86,46],[16,74],[108,70],[64,8]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="1.6" fill="#fff"/>`).join('')}<circle cx="100" cy="30" r="9" fill="#F59E0B"/><ellipse cx="100" cy="30" rx="15" ry="4" fill="none" stroke="#FCD34D" stroke-width="2"/>`;
 else if(a.bg==='bg-library')o+=`<rect width="120" height="120" fill="#F3E3C3"/>${[18,48,78].map(y=>`<rect x="0" y="${y+20}" width="120" height="4" fill="#9C6B3C"/>${[2,10,18,96,104,112].map((x,i)=>`<rect x="${x}" y="${y+4}" width="7" height="16" rx="1" fill="${['#D64545','#3D7DD8','#3DBB76','#F59E0B','#8A55D6'][(i+y)%5]}"/>`).join('')}`).join('')}`;
 else o+=`<rect width="120" height="120" fill="${BGS.honey}"/>`;
 const wings=(c,s)=>`<ellipse cx="26" cy="86" rx="22" ry="14" transform="rotate(-25 26 86)" fill="${c}" stroke="${s}" stroke-width="2" opacity=".95"/><ellipse cx="94" cy="86" rx="22" ry="14" transform="rotate(25 94 86)" fill="${c}" stroke="${s}" stroke-width="2" opacity=".95"/>`;
 if(a.back==='back-wings')o+=wings('#E6F4FF','#9CC9F0');
 if(a.back==='back-fairy'||(kind==='fairy'&&a.back==='none'))o+=wings('#FBE3F5','#F2A7D0');
 if(a.back==='back-jetpack')o+=`<rect x="16" y="88" width="16" height="30" rx="7" fill="#F59E0B" ${OL}/><rect x="88" y="88" width="16" height="30" rx="7" fill="#F59E0B" ${OL}/>`;
 if(a.back==='back-cape')o+=`<path d="M34 94 L14 124 H106 L86 94 Z" fill="#D62839" ${OL}/>`;
 o+=outfit(kind,a,id);
 if(a.acc==='acc-backpack')o+=`<path d="M42 96 L44 124 M78 96 L76 124" stroke="#B45309" stroke-width="5"/>`;
 o+=PEOPLE[kind]?personHead(kind,a):animalHead(kind,a);
 const gy=PEOPLE[kind]?62:(kind==='frog'?36:60),g1=PEOPLE[kind]?47:(kind==='frog'?42:46),g2=PEOPLE[kind]?73:(kind==='frog'?78:74);
 if(a.acc==='acc-glasses')o+=`<circle cx="${g1}" cy="${gy}" r="10" fill="none" stroke="#22386B" stroke-width="2.8"/><circle cx="${g2}" cy="${gy}" r="10" fill="none" stroke="#22386B" stroke-width="2.8"/><path d="M${g1+10} ${gy} H${g2-10}" stroke="#22386B" stroke-width="2.8"/>`;
 if(a.acc==='acc-sunglasses')o+=`<rect x="${g1-11}" y="${gy-7}" width="22" height="14" rx="6" fill="#1F2A44"/><rect x="${g2-11}" y="${gy-7}" width="22" height="14" rx="6" fill="#1F2A44"/><path d="M${g1+11} ${gy-2} H${g2-11}" stroke="#1F2A44" stroke-width="3"/>`;
 if(a.acc==='acc-bowtie')o+=`<path d="M50 90 L58 95 L50 100 Z M70 90 L62 95 L70 100 Z" fill="#D62839"/><circle cx="60" cy="95" r="3" fill="#B91C1C"/>`;
 if(a.acc==='acc-necklace')o+=`<path d="M46 92 Q60 104 74 92" fill="none" stroke="#fff" stroke-width="0"/>${[46,50,55,60,65,70,74].map((x,i)=>`<circle cx="${x}" cy="${92+[0,4,6,7,6,4,0][i]}" r="2.6" fill="#FFF8F0" stroke="#D9CBB8" stroke-width=".8"/>`).join('')}`;
 /* hats */
 const H=a.hat;const pre=o;o='';
 if(H==='hat-bow')o+=`<g transform="translate(82 34)"><path d="M0 0 L-12 -8 L-12 8 Z M0 0 L12 -8 L12 8 Z" fill="#F472B6" ${OL} stroke-linejoin="round"/><circle r="3.5" fill="#EC4899"/></g>`;
 if(H==='hat-cap')o+=`<path d="M26 42 C26 12 94 12 94 42 Z" fill="#D62839" ${OL}/><path d="M60 40 H104 Q104 47 92 47 H60 Z" fill="#B91C1C" ${OL}/>`;
 if(H==='hat-beanie')o+=`<path d="M26 42 C26 8 94 8 94 42 Z" fill="#3D7DD8" ${OL}/><rect x="24" y="36" width="72" height="10" rx="5" fill="#2C62B0"/><circle cx="60" cy="10" r="7" fill="#fff" ${OL}/>`;
 if(H==='hat-party')o+=`<path d="M46 32 L60 -4 L74 32 Z" fill="#8A55D6" ${OL}/>${[[56,22],[64,14],[60,6]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="2.2" fill="#FFD54A"/>`).join('')}<circle cx="60" cy="-3" r="4" fill="#FFD54A"/>`;
 if(H==='hat-chef')o+=`<circle cx="44" cy="16" r="12" fill="#fff" ${OL}/><circle cx="76" cy="16" r="12" fill="#fff" ${OL}/><circle cx="60" cy="10" r="14" fill="#fff" ${OL}/><rect x="36" y="20" width="48" height="18" rx="3" fill="#fff" ${OL}/>`;
 if(H==='hat-tiara')o+=`<path d="M42 36 L46 24 L52 30 L60 16 L68 30 L74 24 L78 36 Z" fill="#E5E7EB" stroke="#9CA3AF" stroke-width="2" stroke-linejoin="round"/><circle cx="60" cy="27" r="3.2" fill="#F472B6"/><circle cx="48" cy="31" r="2" fill="#93C5FD"/><circle cx="72" cy="31" r="2" fill="#93C5FD"/>`;
 if(H==='hat-pirate')o+=`<path d="M18 38 Q60 14 102 38 Q90 30 60 30 Q30 30 18 38Z" fill="#2A2230" ${OL}/><path d="M34 34 C36 6 84 6 86 34 Z" fill="#2A2230" ${OL}/><circle cx="60" cy="22" r="5" fill="#fff"/><path d="M56 30 L64 26 M56 26 L64 30" stroke="#fff" stroke-width="1.8"/>`;
 if(H==='hat-explorer')o+=`<ellipse cx="60" cy="38" rx="46" ry="8" fill="#B08A4E" ${OL}/><path d="M34 38 C34 10 86 10 86 38 Z" fill="#C9A267" ${OL}/><rect x="34" y="31" width="52" height="6" fill="#7A5A2E"/>`;
 if(H==='hat-wizard')o+=`<ellipse cx="60" cy="36" rx="44" ry="8" fill="#4B2A8C" ${OL}/><path d="M36 36 L64 -8 L84 36 Z" fill="#6A3FB8" ${OL} stroke-linejoin="round"/><path d="M60 16 l1.6 3.2 3.4 .5 -2.5 2.4 .6 3.4 -3.1 -1.6 -3.1 1.6 .6 -3.4 -2.5 -2.4 3.4 -.5z" fill="#FFD54A"/>`;
 if(H==='hat-helmet')o+=`<path d="M24 56 C22 14 98 14 96 56 L92 56 C90 30 30 30 28 56 Z" fill="#C3CBD8" ${OL}/><path d="M56 16 Q60 2 64 16" fill="#D62839" ${OL}/><path d="M60 18 Q76 0 88 10 Q76 12 64 22Z" fill="#D62839" ${OL}/>`;
 if(H==='hat-flowers')o+=[[34,36,'#F472B6'],[46,28,'#FFD54A'],[60,25,'#fff'],[74,28,'#F472B6'],[86,36,'#FFD54A']].map(([x,y,c])=>`<circle cx="${x}" cy="${y}" r="6.5" fill="${c}" stroke="#3B2F2F" stroke-width="1.2"/><circle cx="${x}" cy="${y}" r="2.4" fill="#F59E0B"/>`).join('');
 if(H==='hat-crown')o+=`<path d="M38 36 L40 12 L50 24 L60 6 L70 24 L80 12 L82 36 Z" fill="#F5B700" ${OL} stroke-linejoin="round"/><circle cx="60" cy="28" r="3.5" fill="#D62839"/><circle cx="47" cy="31" r="2.5" fill="#3D7DD8"/><circle cx="73" cy="31" r="2.5" fill="#3DBB76"/>`;
 o=pre+(kind==='frog'&&o?`<g transform="translate(0 -14)">${o}</g>`:o);
 if(a.acc==='acc-headphones')o+=`<path d="M24 60 C20 12 100 12 96 60" fill="none" stroke="#1F2A44" stroke-width="5"/><rect x="16" y="52" width="13" height="20" rx="6" fill="#E25555" ${OL}/><rect x="91" y="52" width="13" height="20" rx="6" fill="#E25555" ${OL}/>`;
 if(a.medal==='medal-champ')o+=`<path d="M52 92 L60 104 L68 92" fill="none" stroke="#D62839" stroke-width="4"/><circle cx="60" cy="110" r="8" fill="#F5B700" ${OL}/><path d="M60 105 l1.6 3.2 3.4 .5 -2.5 2.4 .6 3.4 -3.1 -1.6 -3.1 1.6 .6 -3.4 -2.5 -2.4 3.4 -.5z" fill="#fff"/>`;
 if(a.medal==='medal-trophy')o+=`<g transform="translate(72 102)"><path d="M0 0 H16 V5 Q16 13 8 14 Q0 13 0 5 Z" fill="#F5B700" stroke="#B7791F" stroke-width="1.5"/><rect x="6" y="14" width="4" height="4" fill="#B7791F"/><rect x="3" y="18" width="10" height="3" rx="1" fill="#B7791F"/></g>`;
 if(a.acc==='acc-wand')o+=`<path d="M98 120 L104 82" stroke="#8A55D6" stroke-width="4" stroke-linecap="round"/><path d="M104 70 l3 7 7 .5 -5.5 4.5 2 7 -6.5 -4 -6.5 4 2 -7 -5.5 -4.5 7 -.5z" fill="#FFD54A" ${OL} stroke-width="1.5"/>`;
 if(a.acc==='acc-sword')o+=`<path d="M100 74 L104 74 L104 110 L102 114 L100 110 Z" fill="#E5E7EB" ${OL} stroke-width="1.5"/><rect x="94" y="110" width="16" height="4" rx="2" fill="#B7791F"/><rect x="100" y="114" width="4" height="8" fill="#7A5A2E"/>`;
 if(a.acc==='acc-shield')o+=`<path d="M8 92 H32 V106 Q32 118 20 124 Q8 118 8 106 Z" fill="#3D7DD8" ${OL}/><path d="M20 96 V120 M10 106 H30" stroke="#FFD54A" stroke-width="3"/>`;
 if(a.acc==='acc-pencil')o+=`<g transform="rotate(-25 100 100)"><rect x="95" y="76" width="10" height="34" fill="#FFD54A" ${OL} stroke-width="1.5"/><path d="M95 110 L100 120 L105 110 Z" fill="#F3D3A6"/><rect x="95" y="72" width="10" height="5" fill="#F07AB0"/></g>`;
 if(a.pet==='pet-bee')o+=`<g transform="translate(100 22)"><ellipse cx="-4" cy="-7" rx="6" ry="4" fill="#E6F4FF"/><ellipse cx="4" cy="-7" rx="6" ry="4" fill="#E6F4FF"/><ellipse cx="0" cy="0" rx="11" ry="8" fill="#FFD54A" stroke="#3B2F2F" stroke-width="1.5"/><rect x="-4" y="-7" width="3" height="14" fill="#2A2230"/><rect x="3" y="-7" width="3" height="14" fill="#2A2230"/><circle cx="8" cy="-1" r="1.5" fill="#2A2230"/></g>`;
 if(a.pet==='pet-cat')o+=`<g transform="translate(102 104)"><path d="M-10 -6 L-8 -17 L-2 -9 Z M10 -6 L8 -17 L2 -9 Z" fill="#FFB45C" stroke="#3B2F2F" stroke-width="1.5"/><circle cx="0" cy="0" r="11" fill="#FFB45C" stroke="#3B2F2F" stroke-width="1.5"/><ellipse cx="-4" cy="-1" rx="1.8" ry="2.2" fill="#2A2230"/><ellipse cx="4" cy="-1" rx="1.8" ry="2.2" fill="#2A2230"/><path d="M-2 4 Q0 6 2 4" fill="none" stroke="#2A2230" stroke-width="1.2"/></g>`;
 const r=round!==false;
 return `<svg class="avsvg" viewBox="0 0 120 120" width="${size}" height="${size}" role="img" aria-label="avatar">${r?`<clipPath id="${id}r"><circle cx="60" cy="60" r="60"/></clipPath><g clip-path="url(#${id}r)">${o}</g>`:o}</svg>`}


window.SBAvatar={svg:avatarSVG,ANIMALS,PEOPLE};
})();
