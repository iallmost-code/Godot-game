#!/usr/bin/env python3
"""Compose Windswept's original looping score and synthesized effects; needs ffmpeg."""
from pathlib import Path
import math,random,struct,subprocess,tempfile,wave
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'side_scroller/art/audio'
def hz(note):return 440*2**((note-69)/12)
def save(name,samples,ogg=False):
    maximum=max(1,max(abs(x) for x in samples)/.85)
    with tempfile.TemporaryDirectory() as tmp:
        raw=Path(tmp)/'source.wav'
        with wave.open(str(raw),'wb') as w:
            w.setparams((1,2,RATE,0,'NONE','not compressed'))
            w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x/maximum))*32767)) for x in samples))
        if ogg:subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(raw),'-c:a','libvorbis','-q:a','3',str(OUT/(name+'.ogg'))],check=True)
        else:(OUT/(name+'.wav')).write_bytes(raw.read_bytes())
def tone(buffer,start,duration,note,gain=.12,kind='bell'):
    frequency=hz(note)
    for i in range(int(duration*RATE)):
        index=int(start*RATE)+i
        if index>=len(buffer):break
        t=i/RATE
        env=min(1,t/.012)*math.exp(-t*(4 if kind=='bell' else 2)/duration)*min(1,(duration-t)/.04)
        value=math.sin(2*math.pi*frequency*t)+(.25*math.sin(4*math.pi*frequency*t) if kind=='bell' else .12*math.sin(6*math.pi*frequency*t))
        buffer[index]+=value*env*gain
SCORES={
 'meadow':(60,[0,4,7,12,9,7,4,2],[0,5,9,7]),
 'forest':(62,[0,7,10,14,12,10,7,5],[0,5,3,7]),
 'ocean':(65,[0,4,9,7,12,9,4,2],[0,9,5,7]),
 'snow':(67,[12,7,4,2,0,4,7,9],[0,5,2,7]),
 'clockwork':(60,[0,7,4,11,12,7,9,4],[0,9,5,7]),
 'temple':(62,[0,3,7,10,14,12,7,3],[0,8,5,7]),
 'gloom':(57,[0,3,7,10,7,5,3,2],[0,8,5,7]),
 'sky':(64,[0,7,12,16,14,12,9,7],[0,5,9,7]),
 'battle':(57,[0,7,12,10,7,3,5,7],[0,8,5,7])}
OUT.mkdir(parents=True,exist_ok=True)
for name,(base,motif,chords) in SCORES.items():
    beat=.4 if name=='battle' else .5
    length=beat*32
    audio=[0.0]*int(length*RATE)
    for step in range(64):
        chord=chords[(step//16)%4]
        note=base+motif[step%8]+(0 if step%16<8 else 12)
        tone(audio,step*beat/2,beat*.85,note,.075 if name!='battle' else .10)
        tone(audio,step*beat/2,beat*1.2,base-12+chord+[0,7,12,7][step%4],.04,'soft')
    for bar,chord in enumerate(chords):
        for offset in [0,7,12]:tone(audio,bar*8*beat,beat*7.8,base-24+chord+offset,.035,'soft')
    # The final quarter beat fades to silence, keeping each loop click free.
    for i in range(len(audio)):
        t=i/RATE;audio[i]*=min(1,t/.02,(length-t)/.10)
    save(name,audio,True)
rng=random.Random(89)
for name,notes,length in [('star',[91,83],.16),('arrow',[75,63],.18),('spell',[69,76,81],.3),('swing',[55,43],.18),('hit',[50,38],.14),('crit',[86,93],.22),('hurt',[48,43,39],.28),('loot',[84,91],.3),('epic',[72,76,79,84],.75),('level',[72,76,79,84,88],1.0),('warning',[43,43,50],.7),('step',[35],.055)]:
    audio=[0.0]*int(length*RATE)
    for i,note in enumerate(notes):tone(audio,i*length/(len(notes)+1),length*.65,note,.24)
    if name in ['star','arrow','swing','hit','hurt','step']:
        for i in range(len(audio)):
            t=i/RATE;audio[i]+=rng.uniform(-1,1)*math.exp(-t*25)*(0.28 if name=='hit' else .09)
    save(name,audio)
# An original sparse atmosphere bed: wind plus small, widely spaced chimes.
for name in ['breeze','drips','whirr']:
    audio=[0.0]*(RATE*8);smooth=0.0
    for i in range(len(audio)):
        smooth=.985*smooth+.015*rng.uniform(-1,1)
        audio[i]=smooth*.45*math.sin(math.pi*i/len(audio))**2
    for start,note in [(1.2,88),(4.8,93),(6.7,86)]:tone(audio,start,.25,note if name=='breeze' else note-24,.025)
    save(name,audio,True)
print('Composed',len(list(OUT.glob('*.*'))),'original audio assets')
