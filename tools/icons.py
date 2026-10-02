from PIL import Image, ImageDraw
import os,sys
out=sys.argv[1]; os.makedirs(out,exist_ok=True)
def icon(sz, pad=0.0, round_=True):
    S=sz*4; im=Image.new("RGBA",(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    p=int(S*pad)
    if round_: d.rounded_rectangle([p,p,S-p,S-p],radius=int((S-2*p)*0.22),fill=(11,92,173,255))
    else: d.rectangle([0,0,S,S],fill=(11,92,173,255))
    # chip body (SOT-23-like)
    c=S/2; w=(S-2*p)*0.42; h=(S-2*p)*0.26
    d.rounded_rectangle([c-w/2,c-h/2,c+w/2,c+h/2],radius=int(h*0.12),fill=(24,33,43,255),outline=(255,255,255,255),width=max(2,int(S*0.012)))
    lw=w*0.14; ll=(S-2*p)*0.11
    for x in (c-w/3,c+w/3): d.rectangle([x-lw/2,c+h/2,x+lw/2,c+h/2+ll],fill=(230,236,242,255))
    d.rectangle([c-lw/2,c-h/2-ll,c+lw/2,c-h/2],fill=(230,236,242,255))
    d.ellipse([c-w/2+h*0.18,c-h/2+h*0.18,c-w/2+h*0.38,c-h/2+h*0.38],fill=(255,255,255,255))
    return im.resize((sz,sz),Image.LANCZOS)
for n,sz in [("icon-192.png",192),("icon-512.png",512),("favicon-32.png",32)]:
    icon(sz).save(os.path.join(out,n))
icon(512,pad=0.0,round_=False).save(os.path.join(out,"icon-maskable-512.png"))
