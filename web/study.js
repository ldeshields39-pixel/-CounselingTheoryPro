'use strict';
const main = document.querySelector('#view');
const icons = {
 home:'<path d="m3 10 9-7 9 7v10h-6v-6H9v6H3z"/>',search:'<circle cx="10" cy="10" r="6.5"/><path d="m15 15 5 5"/>',
 cards:'<rect x="7" y="6" width="13" height="15" rx="2"/><path d="M16 3H5a2 2 0 0 0-2 2v12"/>',quiz:'<rect x="5" y="4" width="14" height="17" rx="2"/><path d="m8 13 3 3 5-6M9 4V2h6v2"/>',progress:'<path d="M3 20h18M6 16v-4m5 4V8m5 8V4"/>',
 book:'<path d="M12 6v14m0-14C8 3 5 3 2 4v14c3-1 6-1 10 2 4-3 7-3 10-2V4c-3-1-6-1-10 2z"/>',person:'<circle cx="12" cy="7" r="3"/><path d="M5 20v-2a7 7 0 0 1 14 0v2"/>',
 network:'<circle cx="5" cy="16" r="2.5"/><circle cx="12" cy="5" r="2.5"/><circle cx="19" cy="16" r="2.5"/><path d="m6 14 5-7m2 0 5 7m-10 2h8"/>',sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5"/>',
 target:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',tree:'<path d="M12 21V9m0 4-6-4m6 7 6-5"/><path d="M5 13c-5-3-2-8 2-8 2-5 8-5 10 0 5 0 7 6 2 9"/>',
 plan:'<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4m8-4v4m-9 7h3m3 0h3"/>',right:'<path d="m9 5 7 7-7 7"/>',back:'<path d="m14 5-7 7 7 7"/>',arrow:'<path d="M3 12h17m-7-7 7 7-7 7"/>',
 bookmark:'<path d="M6 4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v17l-6-4-6 4z"/>',flip:'<path d="M3 10a9 9 0 0 1 15-5l3 3m0-5v5h-5M21 14A9 9 0 0 1 6 19l-3-3m0 5v-5h5"/>'
};
function icon(k){return '<svg viewBox="0 0 24 24" aria-hidden="true">'+(icons[k]||'')+'</svg>';}
const decks=[
 ['Person-Centered','person','#9ce7ba','Empathy and the therapeutic relationship'],
 ['CBT','network','#90c8ed','Thoughts, behaviors, and beliefs'],
 ['Solution-Focused','sun','#f4ce72','Exceptions and preferred futures'],
 ['Reality Therapy','target','#f1a995','Choices, needs, and evaluation'],
 ['Psychodynamic','tree','#bea9e9','Recurring patterns and unconscious processes']
];
const days=['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const key='counselingTheoryPro.study.v1';
function load(){try{return JSON.parse(localStorage.getItem(key)||'{}')||{};}catch{return {};}}
let state=load();
for(const field of ['seen','favorites','completedDays'])if(!Array.isArray(state[field]))state[field]=[];
if(!Array.isArray(state.sessions))state.sessions=[];
if(!state.last||typeof state.last!=='object')state.last={};
let cards=[],cases=[],casePicks=new Map(),page='home',study=null,quiz=null,origin='home',selected='All theories',qtext='',messageTimer,ready=false;
function say(s){const el=document.querySelector('#message');el.textContent=s;clearTimeout(messageTimer);messageTimer=setTimeout(()=>el.textContent='',2800);}
function save(){try{localStorage.setItem(key,JSON.stringify(state));}catch{say('This browser could not save your progress.');}}
function dateKey(d=new Date()){return [d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-');}
function weekDate(i){const d=new Date();d.setDate(d.getDate()-(d.getDay()+6)%7+i);return dateKey(d);}
function deckCards(i){return cards.filter(c=>c.theory===decks[i]?.[0]);}
function act(id,label,cls='secondary'){return '<button class="'+cls+'" data-do="'+id+'">'+label+'</button>';}
function heading(k,title,sub=''){return '<p class="eyebrow">'+esc(k)+'</p><h1>'+esc(title)+'</h1>'+(sub?'<p class="muted">'+esc(sub)+'</p>':'');}
function back(dest){return act('page:'+dest,icon('back')+' Back','back');}
function meter(n,total){return '<div class="meter" role="progressbar" aria-label="Progress" aria-valuemin="0" aria-valuemax="'+total+'" aria-valuenow="'+n+'"><i style="width:'+Math.min(100,100*n/Math.max(1,total))+'%"></i></div>';}
function row(action,title,sub,glyph){return '<button class="row" data-do="'+action+'"><span class="glyph">'+icon(glyph)+'</span><span><strong>'+esc(title)+'</strong><small>'+esc(sub)+'</small></span>'+icon('right')+'</button>';}
function grid(includePlan){const items=decks.map((d,i)=>[d[0],d[1],d[2],deckCards(i).length+' cards','deck:'+i]);if(includePlan)items.push(['Daily plan','plan','#83d9d2','Your weekly schedule','page:plan']);return '<div class="grid">'+items.map(d=>'<button class="tile" data-do="'+d[4]+'" style="--accent:'+d[2]+'"><span class="glyph">'+icon(d[1])+'</span><strong>'+d[0]+'</strong><small>'+d[3]+'</small></button>').join('')+'</div>';}
function planTitle(i){return decks[i]?.[0]|| (i===5?'Mixed theory review':'Weekly practice quiz');}
function planDescription(i){return decks[i]?.[3]||(i===5?'Revisit concepts across the five decks':'Check your recall with ten questions');}
function home(){const i=(new Date().getDay()+6)%7;return heading('Study guide','Counseling theories')+'<section class="feature"><p class="eyebrow">'+days[i]+' · Daily study</p><h2>'+planTitle(i)+'</h2><p class="muted">'+planDescription(i)+'.</p>'+act('day:'+i,'Start session '+icon('arrow'),'primary')+'</section><div class="section-head"><h2>Your library</h2><small>'+cards.length+' flashcards</small></div>'+grid(true);}
function library(){return heading('Your library','Flashcards','Choose a deck or revisit the cards you saved.')+grid(false)+'<h2>Review sets</h2><div class="stack">'+row('mixed','Mixed deck','Study all five theories','cards')+row('favorites','Favorites',favoriteCards().length+' saved cards','bookmark')+'</div>';}
function plan(){return back('home')+heading('Study rhythm','Daily study plan')+'<div class="stack">'+days.map((d,i)=>'<button class="row" data-do="day:'+i+'"><span class="day" style="--accent:'+(decks[i]?.[2]||'#9ce7ba')+'">'+d.slice(0,3).toUpperCase()+'</span><span><strong>'+planTitle(i)+'</strong><small>'+planDescription(i)+(state.completedDays.includes(weekDate(i))?' · Completed':'')+'</small></span>'+icon('right')+'</button>').join('')+'</div>';}
function favoriteCards(){return cards.filter(c=>state.favorites.includes(c.id));}
function beginStudy(list,title,setId,day=null,index=null){origin=page;study={list,title,setId,day,reviewed:new Set(),pos:index??Math.max(0,list.findIndex(c=>c.id===state.last[setId])),flipped:false};navigate('study');}
function studyView(){const s=study,c=s.list[s.pos];if(!c)return back(origin)+heading('Saved cards','Favorites','Tap the bookmark on any flashcard to save it here.');const fav=state.favorites.includes(c.id);return back(origin)+heading('Flashcards',s.title)+'<div class="toolrow"><span class="count">Card '+(s.pos+1)+' of '+s.list.length+'</span><button class="bookmark" data-do="bookmark" aria-label="'+(fav?'Remove from':'Add to')+' favorites" aria-pressed="'+fav+'">'+icon('bookmark')+'</button></div>'+meter(s.pos+1,s.list.length)+'<button class="paper" data-do="flip" aria-label="'+esc((s.flipped?c.term+'. '+c.answer:c.question)+(s.flipped?' Tap to see question.':' Tap to reveal answer.'))+'"><span class="eyebrow">'+esc(c.theory)+' · '+(s.flipped?'Answer':'Question')+'</span><span class="'+(s.flipped?'answer':'prompt')+'">'+(s.flipped?'<strong class="term">'+esc(c.term)+'</strong>'+esc(c.answer):esc(c.question))+'</span><small>'+icon('flip')+' Tap to '+(s.flipped?'see question':'reveal')+'</small></button><div class="toolrow"><button class="secondary" data-do="prev" '+(s.pos===0?'disabled':'')+'>'+icon('back')+' Previous</button>'+act(s.pos===s.list.length-1?'studyEnd':'next',s.pos===s.list.length-1?'Finish session':'Next '+icon('right'),'primary')+'</div>';}
function shuffled(seq){const copy=[...seq];for(let i=copy.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[copy[i],copy[j]]=[copy[j],copy[i]];}return copy;}
function quizSetup(){return heading('Recall practice','Practice quiz','Answer up to ten questions and review the explanation after each choice.')+'<div class="panel"><label for="scope">Question pool</label><select id="scope">'+['All theories',...decks.map(d=>d[0])].map(s=>'<option '+(selected===s?'selected':'')+'>'+s+'</option>').join('')+'</select>'+act('quizStart','Begin quiz '+icon('arrow'),'primary')+'</div>';}
function beginQuiz(day=null){const pool=day!==null||selected==='All theories'?cards:cards.filter(c=>c.theory===selected);let qs=shuffled(pool).slice(0,10).map(c=>{const candidates=[...shuffled(pool),...shuffled(cards)];const distractors=[...new Set(candidates.map(x=>x.term).filter(s=>s.toLowerCase()!==c.term.toLowerCase()))].slice(0,3);return {card:c,choices:shuffled([c.term,...distractors]),pick:null};});quiz={qs,i:0,day};navigate('quizRun');}
function quizView(){const {qs,i}=quiz, item=qs[i],chosen=item.pick!==null;return heading('Question '+(i+1)+' of '+qs.length,'Practice quiz')+meter(i+1,qs.length)+'<h2>'+esc(item.card.question)+'</h2><div class="stack">'+item.choices.map((s,k)=>'<button data-do="pick:'+k+'" '+(chosen?'disabled':'')+' class="option '+(chosen&&s===item.card.term?'right':chosen&&k===item.pick?'wrong':'')+'">'+esc(s)+'</button>').join('')+'</div>'+(chosen?'<div class="panel" role="status"><strong>'+(item.choices[item.pick]===item.card.term?'Correct':'Review this concept')+'</strong><p><b>'+esc(item.card.term)+'</b></p><p>'+esc(item.card.answer)+'</p></div>'+act('quizNext',i+1===qs.length?'See results':'Next question','primary'):'');}
function finishDay(i){if(i!=null&&!state.completedDays.includes(weekDate(i)))state.completedDays.push(weekDate(i));}
function results(){const qs=quiz.qs,score=qs.filter(x=>x.choices[x.pick]===x.card.term).length;return heading('Session complete','Your results')+'<section class="feature"><h2>'+score+' / '+qs.length+' correct</h2>'+act('page:quiz','Practice again','primary')+'</section><h2>Review</h2>'+qs.map(x=>'<details><summary>'+esc(x.card.question)+'</summary><p>Your answer · '+esc(x.choices[x.pick])+'</p><p>Correct answer · '+esc(x.card.term)+'</p><p>'+esc(x.card.answer)+'</p></details>').join('');}
function progress(){const correct=state.sessions.reduce((s,x)=>s+(x.correct||0),0),total=state.sessions.reduce((s,x)=>s+(x.total||0),0);return heading('Study record','Your progress')+'<div class="stats">'+[[state.seen.length,'Cards reviewed'],[state.sessions.length,'Quizzes finished'],[total?Math.round(correct*100/total)+'%':'—','Quiz accuracy']].map(x=>'<div><b>'+x[0]+'</b><small>'+x[1]+'</small></div>').join('')+'</div><h2>Deck coverage</h2><div class="panel">'+decks.map((d,i)=>{const pool=deckCards(i),n=pool.filter(c=>state.seen.includes(c.id)).length;return '<div style="--accent:'+d[2]+'"><strong>'+d[0]+'</strong> <small>'+n+' / '+pool.length+'</small>'+meter(n,pool.length)+'</div>';}).join('')+'</div><p class="muted note">Progress is saved in this browser on this device.</p>';}
function examCases(){return '<h2>NCE case practice</h2><p class="muted">Choose a response to see the rationale.</p>'+cases.map((item,i)=>{
 const chosen=casePicks.has(i), pick=casePicks.get(i);
 return '<article class="panel"><p class="eyebrow">'+esc(item.domain)+'</p><h3>'+esc(item.prompt)+'</h3><div class="stack">'+item.choices.map((choice,j)=>'<button class="option '+(chosen&&j===item.correct?'right':chosen&&j===pick?'wrong':'')+'" data-do="case:'+i+'-'+j+'" '+(chosen?'disabled':'')+'>'+esc(choice)+'</button>').join('')+'</div>'+(chosen?'<p class="caseRationale" role="status"><strong>'+(pick===item.correct?'Correct. ':'Correct answer: '+esc(item.choices[item.correct])+'. ')+'</strong>'+esc(item.rationale)+'</p>':'')+'</article>';
}).join('')+(casePicks.size?act('resetCases','Try the cases again'):'');}
function resources(){return heading('Student resources','Reference desk')+'<h2>NCE exam review</h2><div class="panel"><p>Use the content outline for your scheduled exam date to organize review. Pair a content area with an original practice vignette, then explain why each alternative is less suitable.</p><a href="https://www.nbcc.org/exams/nce/" target="_blank" rel="noopener">NBCC exam outlines and preparation ↗</a></div><h2>DSM-5-TR quick reference</h2>'+[
 ['Classification','The DSM-5-TR organizes mental disorders into diagnostic categories. In a study vignette, identify the symptoms, course, impairment, context, and missing information before comparing possibilities.'],
 ['Differential diagnosis','Consider what additional history would distinguish explanations. Compare symptom timing, medical and substance-related factors, and the client’s cultural context. Consult the current manual for criteria and exclusions.'],
 ['Specifiers and severity','A specifier adds detail to an established diagnosis. Severity and course descriptions vary by diagnosis. Check the relevant entry before applying a term.'],
 ['Assessment measures','Cross-cutting measures can identify symptom areas for further inquiry. A score alone cannot establish a diagnosis.']
 ].map(([t,b])=>'<details><summary>'+t+'</summary><p>'+b+'</p></details>').join('')+'<p class="note"><a href="https://www.psychiatry.org/psychiatrists/practice/dsm/educational-resources" target="_blank" rel="noopener">APA educational resources ↗</a></p>'+examCases()+'<h2>Test-taking strategies</h2><div class="panel"><ol><li>Identify the task word, such as <em>first</em>, <em>best</em>, or <em>most likely</em>.</li><li>Predict a response before reading the choices.</li><li>Compare each choice with the details given in the stem.</li><li>After practice, explain one distractor and the detail that ruled it out.</li></ol></div><p class="note muted">Independent study guide. The practice items are original and do not represent official NCE questions.</p>';}
function searchResults(){const q=qtext.trim().toLowerCase();const hits=q?cards.filter(c=>[c.term,c.question,c.answer,c.theory].join(' ').toLowerCase().includes(q)):[];return '<p class="count" role="status">'+(q?hits.length+' matching cards':'Search by concept, theory, or keyword.')+'</p><div class="stack">'+hits.map(c=>row('found:'+cards.indexOf(c),c.question,c.theory,'cards')).join('')+'</div>';}
function searchView(){return heading('Library index','Search')+'<label for="query">Find a flashcard</label><input type="search" id="query" placeholder="Try empathy or exceptions" value="'+esc(qtext)+'"><div id="matches">'+searchResults()+'</div>';}
const screens={home,library,plan,study:studyView,quiz:quizSetup,quizRun:quizView,results,progress,resources,search:searchView,complete:()=>heading('Session complete','Study session finished')+'<div class="panel"><p>'+esc(study.title)+' · '+study.reviewed.size+' of '+study.list.length+' answers reviewed.</p>'+act('page:library','Choose another deck','primary')+'</div>'};
function render(){if(!ready)return;main.innerHTML=screens[page]();const active=({study:'library',complete:'library',plan:'home',search:'library',quizRun:'quiz',results:'quiz'})[page]||page;document.querySelector('nav').innerHTML=[['home','home','Home'],['library','cards','Cards'],['quiz','quiz','Quiz'],['progress','progress','Progress'],['resources','book','Reference']].map(([p,k,t])=>'<button data-do="page:'+p+'" '+(active===p?'aria-current="page"':'')+'>'+icon(k)+'<span>'+t+'</span></button>').join('');}
function navigate(p){if(!ready)return;page=p;render();window.scrollTo(0,0);main.focus({preventScroll:true});}
function remember(){state.last[study.setId]=study.list[study.pos].id;save();}
document.addEventListener('click',event=>{
 const el=event.target.closest('[data-do]');if(!el||!ready)return;
 const [cmd,arg]=el.dataset.do.split(':'),n=Number(arg);
 switch(cmd){
 case 'page':navigate(arg);break;
 case 'case':{const [i,j]=arg.split('-').map(Number);if(!casePicks.has(i))casePicks.set(i,j);render();break;}
 case 'resetCases':casePicks.clear();render();break;
 case 'deck':beginStudy(deckCards(n),decks[n][0],'deck'+n);break;
 case 'day':if(n===6)beginQuiz(n);else {const pool=n<5?deckCards(n):cards;const offset=Math.floor((Date.parse(weekDate(n)+'T12:00:00Z')/86400000)/7)*7;const sequence=Array.from({length:Math.min(10,pool.length)},(_,i)=>pool[(i+offset)%pool.length]);beginStudy(sequence,planTitle(n),weekDate(n),n,0);}break;
 case 'found':beginStudy([cards[n]],cards[n].theory,'search',null,0);break;
 case 'favorites':beginStudy(favoriteCards(),'Favorites','favorites');break;
 case 'mixed':beginStudy(cards,'Mixed deck','mixed');break;
 case 'bookmark':{const id=study.list[study.pos].id;state.favorites=state.favorites.includes(id)?state.favorites.filter(x=>x!==id):[...state.favorites,id];save();render();say(state.favorites.includes(id)?'Saved to favorites':'Removed from favorites');break;}
 case 'flip':{study.flipped=!study.flipped;const id=study.list[study.pos].id;if(study.flipped){study.reviewed.add(id);if(!state.seen.includes(id))state.seen.push(id);}remember();render();const paper=document.querySelector('.paper');paper.classList.add('turn');paper.focus({preventScroll:true});break;}
 case 'prev':case 'next':{study.pos+=cmd==='next'?1:-1;study.flipped=false;remember();render();break;}
 case 'studyEnd':{if(study.reviewed.size===study.list.length)finishDay(study.day);delete state.last[study.setId];save();navigate('complete');break;}
 case 'quizStart':selected=document.querySelector('#scope').value;beginQuiz();break;
 case 'pick':{const x=quiz.qs[quiz.i];if(x.pick===null)x.pick=n;render();break;}
 case 'quizNext':{if(quiz.i<quiz.qs.length-1){quiz.i++;navigate('quizRun');}else{state.sessions.push({date:dateKey(),correct:quiz.qs.filter(x=>x.choices[x.pick]===x.card.term).length,total:quiz.qs.length});finishDay(quiz.day);save();navigate('results');}break;}
 }
});
document.addEventListener('input',e=>{if(e.target.id==='query'){qtext=e.target.value;document.querySelector('#matches').innerHTML=searchResults();}});
document.querySelector('#brand').onclick=()=>navigate('home');
const searchButton=document.querySelector('#searchButton');searchButton.innerHTML=icon('search');searchButton.onclick=()=>{navigate('search');document.querySelector('#query')?.focus();};
async function start(){try{const response=await fetch('cards.json');if(!response.ok)throw Error();cards=await response.json();const examResponse=await fetch('exam.json');if(examResponse.ok){cases=await examResponse.json();}if(!Array.isArray(cards)||cards.length<1)throw Error();ready=true;render();if('serviceWorker' in navigator)navigator.serviceWorker.register('sw.js').catch(()=>{});}catch{main.innerHTML='<h1>Study guide unavailable</h1><p>Please reconnect and try opening the guide again.</p><button class="primary" id="retry">Try again</button>';document.querySelector('#retry').onclick=start;}}
start();
