# 生成 1024x1024 手绘风游戏图标：python3 tools/gen_icon.py  （输出 icon.png，无透明通道，符合 iOS 要求）
import numpy as np, random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
S=2; N=1024*S
random.seed(11); rng=np.random.default_rng(11)
def jit(pts,a,seed,closed=True):
    r=random.Random(seed); out=[]; n=len(pts)
    for i in range(n if closed else n-1):
        p,q=pts[i],pts[(i+1)%n]; k=max(1,int(math.dist(p,q)/(40*S/2)))
        for j in range(k):
            t=j/k; out.append((p[0]+(q[0]-p[0])*t+r.uniform(-a,a),p[1]+(q[1]-p[1])*t+r.uniform(-a,a)))
    out.append(out[0] if closed else pts[-1]); return out
def rr(x0,y0,x1,y1,rad):
    pts=[]; cs=[(x0+rad,y0+rad),(x1-rad,y0+rad),(x1-rad,y1-rad),(x0+rad,y1-rad)]
    for i in range(4):
        for k in range(8):
            a=math.pi+i*math.pi/2+k*(math.pi/2)/7; pts.append((cs[i][0]+math.cos(a)*rad,cs[i][1]+math.sin(a)*rad))
    return pts
# 背景：深蓝牛皮纸 + 水彩晕染 + 颗粒
y=np.linspace(0,1,N)[:,None,None]
base=(np.array([0.07,0.09,0.2])*(1-y)+np.array([0.14,0.08,0.2])*y)*np.ones((N,N,3))
blob=Image.new('RGB',(N,N)); bd=ImageDraw.Draw(blob)
for col,n in (((40,110,120),6),((130,50,80),5),((150,100,40),3)):
    for _ in range(n):
        cx,cy=random.randint(0,N),random.randint(0,N); rx=random.randint(250,600)*S//2; ry=random.randint(200,500)*S//2
        bd.ellipse((cx-rx,cy-ry,cx+rx,cy+ry),fill=col)
blob=blob.filter(ImageFilter.GaussianBlur(120*S/2))
bg=np.clip(base*255*0.7+np.asarray(blob,np.float32)*0.5+rng.normal(0,5,(N,N,1)),0,255)
img=Image.fromarray(bg.astype(np.uint8)).convert('RGBA'); d=ImageDraw.Draw(img,'RGBA')
def stroke(dr,pts,col,w,seed,closed=True):
    dr.line(jit(pts,2.4*S,seed,closed),fill=col,width=int(w*S),joint='curve')
    dr.line(jit(pts,3.2*S,seed+977,closed),fill=col[:3]+(int(col[3]*0.5),),width=max(1,int(w*S*0.55)),joint='curve')
CH=(243,235,209); GOLD=(250,209,107)
def star(dr,x,y,r,col,seed):
    stroke(dr,[(x-r,y),(x+r,y)],col,5,seed,False); stroke(dr,[(x,y-r),(x,y+r)],col,5,seed+3,False)
    stroke(dr,[(x-r*.5,y-r*.5),(x+r*.5,y+r*.5)],col[:3]+(150,),3,seed+5,False); stroke(dr,[(x+r*.5,y-r*.5),(x-r*.5,y+r*.5)],col[:3]+(150,),3,seed+7,False)
c=N//2
ring=[(c+math.cos(a/90*math.tau)*440*S,c+math.sin(a/90*math.tau)*440*S) for a in range(90)]
stroke(d,ring,CH+(150,),6,3); stroke(d,[(c+math.cos(a/90*math.tau)*410*S,c+math.sin(a/90*math.tau)*410*S) for a in range(90)],CH+(70,),3,9)
for i in range(48):
    a=i/48*math.tau; l=18+16*random.random()
    stroke(d,[(c+math.cos(a)*410*S,c+math.sin(a)*410*S),(c+math.cos(a)*(410-l)*S,c+math.sin(a)*(410-l)*S)],CH+(110,),3,100+i,False)
for _ in range(26):
    ang=random.random()*math.tau; r=random.uniform(450,500)*S
    star(d,c+math.cos(ang)*r,c+math.sin(ang)*r,random.choice((14,20,26))*S/2,CH+(random.randint(120,220),),random.randint(0,999))
# 卡牌（单独一层再旋转）
L=Image.new('RGBA',(N,N),(0,0,0,0)); ld=ImageDraw.Draw(L,'RGBA')
x0,y0,x1,y1=c-290*S,c-380*S,c+290*S,c+380*S
card=rr(x0,y0,x1,y1,60*S); ld.polygon(card,fill=(248,238,212,255))
stroke(ld,rr(x0+4*S,y0+4*S,x1-4*S,y1-4*S,58*S),(36,28,44,255),11,5)
stroke(ld,rr(x0+34*S,y0+34*S,x1-34*S,y1-34*S,36*S),(120,86,52,150),4,6)
# 小丑：三角帽 + 铃铛 + 脸
fx,fy=c,c+70*S
hat=[(fx-150*S,fy-110*S),(fx-250*S,fy-300*S),(fx-70*S,fy-200*S),(fx,fy-350*S),(fx+70*S,fy-200*S),(fx+250*S,fy-300*S),(fx+150*S,fy-110*S)]
ld.polygon([hat[0],hat[1],hat[2],(fx-60*S,fy-110*S)],fill=(224,86,92,255)); ld.polygon([hat[2],hat[3],hat[4],(fx,fy-110*S)],fill=(76,189,189,255)); ld.polygon([hat[4],hat[5],hat[6],(fx+60*S,fy-110*S)],fill=(224,86,92,255))
stroke(ld,hat,(36,28,44,255),10,21)
for p in (hat[1],hat[3],hat[5]):
    ld.ellipse((p[0]-30*S,p[1]-30*S,p[0]+30*S,p[1]+30*S),fill=GOLD+(255,)); stroke(ld,[(p[0]+math.cos(a/16*math.tau)*30*S,p[1]+math.sin(a/16*math.tau)*30*S) for a in range(16)],(36,28,44,255),6,int(p[0]))
ld.rectangle((fx-165*S,fy-125*S,fx+165*S,fy-95*S),fill=GOLD+(255,)); stroke(ld,[(fx-165*S,fy-125*S),(fx+165*S,fy-125*S),(fx+165*S,fy-95*S),(fx-165*S,fy-95*S)],(36,28,44,255),7,33)
ld.ellipse((fx-150*S,fy-110*S,fx+150*S,fy+190*S),fill=(250,220,184,255)); stroke(ld,[(fx+math.cos(a/40*math.tau)*150*S,fy+40*S+math.sin(a/40*math.tau)*150*S) for a in range(40)],(36,28,44,255),10,41)
for s in (-1,1):
    ld.ellipse((fx+s*58*S-18*S,fy-20*S-18*S,fx+s*58*S+18*S,fy-20*S+18*S),fill=(36,28,44,255))
    ld.ellipse((fx+s*95*S-30*S,fy+50*S-24*S,fx+s*95*S+30*S,fy+50*S+24*S),fill=(255,140,140,120))
mouth=[(fx+math.cos(a/16*math.pi)*70*S,fy+80*S+math.sin(a/16*math.pi)*52*S) for a in range(17)]
stroke(ld,mouth,(36,28,44,255),10,55,False)
for k,(sx,sy) in enumerate(((x0+95*S,y0+110*S),(x1-95*S,y1-110*S))):
    ld.text((sx,sy),"J",font=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',150*S,index=2),fill=(30,36,86,255),anchor='mm')
    star(ld,sx,sy+120*S if k==0 else sy-120*S,22*S,(200,40,70,255),70+k)
star(ld,fx+170*S,fy+260*S,40*S,GOLD+(255,),80); star(ld,fx-190*S,fy+250*S,28*S,GOLD+(255,),81)
sh=L.rotate(-8,resample=Image.BICUBIC)
shadow=Image.new('RGBA',(N,N),(0,0,0,0)); shadow.paste((0,0,0,150),mask=sh.split()[3]); shadow=shadow.filter(ImageFilter.GaussianBlur(26*S)).transform((N,N),Image.AFFINE,(1,0,-14*S,0,1,-24*S))
img=Image.alpha_composite(Image.alpha_composite(img,shadow),sh)
img.convert('RGB').resize((1024,1024),Image.LANCZOS).save('icon.png'); print('icon ok')
