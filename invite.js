/* Spelling Bee — invitation card (shared by teacher.html and invitation.html) */
(function(){
"use strict";
const THEMES={
 honey:{name:'Honey & navy',bg:'#1B3A6B',accent:'#F5B700',soft:'#FFF3C4',ink:'#1F2A44',head:'#FFD54A'},
 garden:{name:'Pink garden',bg:'#9D174D',accent:'#F9A8D4',soft:'#FFE8F1',ink:'#3B1129',head:'#FFE4F0'},
 sky:{name:'Sky blue',bg:'#1E40AF',accent:'#93C5FD',soft:'#E0ECFF',ink:'#14234B',head:'#DBEAFE'},
 royal:{name:'Royal purple',bg:'#5B21B6',accent:'#C4B5FD',soft:'#EFE7FF',ink:'#24104F',head:'#EDE9FE'}};
const FIELDS=[
 ['headline','Headline','You’re invited!'],
 ['title','Event name','The Big Spelling Bee Grand Final'],
 ['to','Who it’s for','Dear Parents and Families,'],
 ['message','Message',''],
 ['date','Date',''],['time','Time',''],['place','Place',''],
 ['details','Extra details (optional)',''],
 ['rsvp','How to reply (optional)',''],
 ['signoff','From','The Spelling Bee Team']];
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function nl(s){return esc(s).replace(/\n/g,'<br>')}
const BEE=`<svg viewBox="0 0 100 100" aria-hidden="true"><ellipse cx="40" cy="30" rx="16" ry="20" fill="#fff" opacity=".9"/><ellipse cx="60" cy="28" rx="14" ry="18" fill="#E8F4FF" opacity=".9"/><ellipse cx="50" cy="58" rx="30" ry="22" fill="#FFC72C"/><path d="M36 39 Q32 58 36 78" stroke="#1F2A44" stroke-width="7" fill="none"/><path d="M52 36 Q48 58 52 80" stroke="#1F2A44" stroke-width="7" fill="none"/><circle cx="78" cy="54" r="13" fill="#1F2A44"/><circle cx="82" cy="51" r="3.4" fill="#fff"/><path d="M76 62 Q81 66 86 61" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round"/><path d="M76 42 Q74 30 68 28 M84 42 Q88 31 94 31" stroke="#1F2A44" stroke-width="2.5" fill="none"/><circle cx="68" cy="28" r="3" fill="#1F2A44"/><circle cx="94" cy="31" r="3" fill="#1F2A44"/></svg>`;
function combs(color){return `<svg class="inv-combs" viewBox="0 0 100 60" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><defs><pattern id="ihc" width="12" height="20.78" patternUnits="userSpaceOnUse"><polygon points="6,0 12,3.46 12,10.39 6,13.86 0,10.39 0,3.46" fill="none" stroke="${color}" stroke-width=".8"/><polygon points="12,10.39 18,13.86 18,20.78 12,24.25 6,20.78 6,13.86" fill="none" stroke="${color}" stroke-width=".8"/></pattern></defs><rect width="100" height="60" fill="url(#ihc)"/></svg>`}
function safeLogo(u){return typeof u==='string'&&/^data:image\/(png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(u)?u:''}
/* moved items keep an offset (in % of the card width) and some items have a size */
const MOVABLE={logo:'School logo',head:'Headline',title:'Event name',bee1:'Big bee',bee2:'Small bee',to:'Greeting',msg:'Message',facts:'Date, time and place',det:'Extra details',rsvp:'How to reply',sign:'From'};
const SIZES=[['logo','Logo size'],['head','Headline size'],['title','Event name size'],['body','Text size'],['top','Coloured top area']];
function num(v,lo,hi,def){v=+v;return isFinite(v)?Math.max(lo,Math.min(hi,v)):def}
function card(d){d=d||{};const t=THEMES[d.theme]||THEMES.honey;const logo=safeLogo(d.logo);const P=d.pos||{},S=d.size||{};
 const mv=n=>{const p=P[n]||[0,0];return ` data-mv="${n}" style="translate:${num(p[0],-100,100,0)}cqw ${num(p[1],-150,150,0)}cqw"`};
 const sz=n=>num(S[n],0.5,2,1);
 const row=(ic,label,v)=>v?`<div class="inv-row"><span class="inv-ic">${ic}</span><div><div class="inv-lb">${label}</div><div class="inv-v">${nl(v)}</div></div></div>`:'';
 return `<div class="inv" style="--bg:${t.bg};--ac:${t.accent};--soft:${t.soft};--ink:${t.ink};--head:${t.head};--zl:${sz('logo')};--zh:${sz('head')};--zt:${sz('title')};--zb:${sz('body')};--zp:${sz('top')}">
  <div class="inv-top"><div class="inv-topbg">${combs(t.accent)}</div><div class="inv-bee"${mv('bee1')}>${BEE}</div><div class="inv-bee b2"${mv('bee2')}>${BEE}</div>
   ${logo?`<div class="inv-logo"${mv('logo')}><img src="${logo}" alt="School logo"></div>`:''}<div class="inv-head"${mv('head')}>${nl(d.headline||'')}</div><div class="inv-title"${mv('title')}>${nl(d.title||'')}</div></div>
  <div class="inv-body">
   ${d.to?`<div class="inv-to"${mv('to')}>${nl(d.to)}</div>`:''}
   ${d.message?`<div class="inv-msg"${mv('msg')}>${nl(d.message)}</div>`:''}
   <div class="inv-facts"${mv('facts')}>${row('📅','Date',d.date)}${row('⏰','Time',d.time)}${row('📍','Place',d.place)}</div>
   ${d.details?`<div class="inv-det"${mv('det')}>${nl(d.details)}</div>`:''}
   ${d.rsvp?`<div class="inv-rsvp"${mv('rsvp')}><b>Please reply</b><br>${nl(d.rsvp)}</div>`:''}
   ${d.signoff?`<div class="inv-sign"${mv('sign')}>With warm wishes,<br><b>${nl(d.signoff)}</b></div>`:''}
  </div>
  <div class="inv-foot">🐝 Spell it! Say it! Shine! ✨</div></div>`}
const CSS=`
.inv{position:relative;width:100%;max-width:640px;aspect-ratio:1/1.414;margin:0 auto;background:#fff;border-radius:28px;box-shadow:0 14px 40px rgba(31,42,68,.18);display:flex;flex-direction:column;font-family:Nunito,system-ui,sans-serif;color:var(--ink);border:6px solid var(--ac);container-type:inline-size}
.inv-top{position:relative;color:#fff;text-align:center;padding:6cqw 6cqw calc(10cqw * var(--zp,1) * var(--zp,1))}
.inv-topbg{position:absolute;inset:0;overflow:hidden;background:var(--bg);border-radius:22px 22px 50% 50%/22px 22px 7cqw 7cqw}
.inv-combs{position:absolute;inset:0;width:100%;height:100%;opacity:.18}
.inv-bee{position:absolute;width:13cqw;height:13cqw;left:5cqw;top:5cqw;transform:rotate(-12deg)}.inv-bee.b2{left:auto;right:5cqw;top:auto;bottom:6cqw;width:10cqw;height:10cqw;transform:scaleX(-1) rotate(-10deg)}
.inv-logo{position:relative;display:inline-flex;align-items:center;justify-content:center;background:#fff;border-radius:3cqw;padding:1.6cqw 2.6cqw;margin-bottom:2.4cqw;box-shadow:0 .8cqw 2cqw rgba(0,0,0,.18)}
.inv-logo img{display:block;max-height:calc(12cqw * var(--zl,1));max-width:calc(40cqw * var(--zl,1));object-fit:contain}
.inv-head{position:relative;font-family:Fredoka,Nunito,sans-serif;font-weight:700;font-size:calc(5.4cqw * var(--zh,1));color:var(--head);letter-spacing:.02em}
.inv-title{position:relative;font-family:Fredoka,Nunito,sans-serif;font-weight:700;font-size:calc(8.6cqw * var(--zt,1));line-height:1.05;margin-top:1.5cqw;color:#fff;text-shadow:0 .6cqw 0 rgba(0,0,0,.18)}
.inv-body{flex:1;padding:3.6cqw 7.5cqw 2.6cqw;display:flex;flex-direction:column;gap:2cqw;font-size:calc(2.95cqw * var(--zb,1));line-height:1.4}
.inv-to{font-weight:800;font-size:calc(3.4cqw * var(--zb,1))}
.inv-msg{font-size:calc(3.05cqw * var(--zb,1))}
.inv-facts{display:grid;gap:1.3cqw;background:var(--soft);border-radius:4cqw;padding:2.6cqw 4cqw}
.inv-row{display:flex;gap:3cqw;align-items:center}.inv-ic{font-size:5cqw;line-height:1}
.inv-lb{font-size:2.3cqw;font-weight:800;text-transform:uppercase;letter-spacing:.08em;opacity:.65}.inv-v{font-family:Fredoka,Nunito,sans-serif;font-weight:600;font-size:calc(3.5cqw * var(--zb,1));line-height:1.2}
.inv-det{font-size:calc(2.85cqw * var(--zb,1))}
.inv-rsvp{border:.5cqw dashed var(--ac);border-radius:3cqw;padding:2.2cqw 3cqw;font-size:calc(2.9cqw * var(--zb,1))}
.inv-sign{margin-top:auto;font-size:calc(2.9cqw * var(--zb,1))}
.inv-foot{background:var(--ac);color:var(--ink);text-align:center;font-family:Fredoka,Nunito,sans-serif;font-weight:700;font-size:3.2cqw;padding:2.2cqw;border-radius:0 0 22px 22px}
.inv-editing [data-mv]{cursor:move;outline:2px dashed rgba(245,183,0,.9);outline-offset:3px;touch-action:none;user-select:none;-webkit-user-select:none}
.inv-editing [data-mv]:hover{outline-color:#E11D48}.inv-editing [data-mv].dragging{outline:3px solid #E11D48;z-index:5}
.inv [data-mv]{position:relative}.inv-bee[data-mv]{position:absolute}
@media print{.inv{box-shadow:none;-webkit-print-color-adjust:exact;print-color-adjust:exact}}
/* print sheets */
.inv-sheet{display:none}
@media print{
 body.inv-printing>*:not(.inv-sheet){display:none!important}
 body.inv-printing .inv-sheet{display:block!important}
 .inv-sheet .inv-page{page-break-after:always;break-after:page;display:flex;align-items:center;justify-content:center}
 .inv-sheet .inv-page:last-child{page-break-after:auto;break-after:auto}
 .inv-sheet.one .inv-page{height:277mm}.inv-sheet.one .inv{width:186mm;max-width:none;border-radius:8mm}
 .inv-sheet.two .inv-page{height:277mm;flex-direction:column;gap:6mm}.inv-sheet.two .inv{width:90mm;max-width:none;border-radius:5mm}
 body.inv-printing{background:#fff!important}
 @page{size:A4 portrait;margin:10mm}}`;
function injectCSS(){if(document.getElementById('inv-css'))return;const s=document.createElement('style');s.id='inv-css';s.textContent=CSS;document.head.appendChild(s)}
/* layout: 'one' = 1 per A4 page, 'two' = 2 per A4 page (A5 size) */
function print(d,layout,copies){injectCSS();let sh=document.querySelector('.inv-sheet');if(!sh){sh=document.createElement('div');document.body.appendChild(sh)}
 layout=layout==='two'?'two':'one';copies=Math.max(1,Math.min(200,+copies||1));sh.className='inv-sheet '+layout;
 const per=layout==='two'?2:1,pages=Math.ceil(copies/per);let h='';for(let p=0;p<pages;p++){let c='';for(let i=0;i<per&&p*per+i<copies;i++)c+=card(d);h+=`<div class="inv-page">${c}</div>`}
 sh.innerHTML=h;
 /* make sure each card fits its page: measure the card's shape on screen, then size it in mm */
 try{const m=document.createElement('div');m.style.cssText='position:absolute;left:-9999px;top:0;width:600px';m.innerHTML=card(d);document.body.appendChild(m);
  const el=m.querySelector('.inv');const ratio=el.getBoundingClientRect().height/el.getBoundingClientRect().width;m.remove();
  const availH=layout==='two'?(277-8)/2:272,maxW=layout==='two'?96:186,w=Math.min(maxW,availH/ratio);
  sh.querySelectorAll('.inv').forEach(c=>{c.style.width=w.toFixed(1)+'mm'})}catch(e){}
 document.body.classList.add('inv-printing');const done=()=>{document.body.classList.remove('inv-printing');window.removeEventListener('afterprint',done)};window.addEventListener('afterprint',done);
 setTimeout(()=>{window.print();setTimeout(done,1000)},200)}
window.SBInvite={THEMES,FIELDS,MOVABLE,SIZES,card,injectCSS,print};
})();
