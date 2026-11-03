import sys,os,hashlib,json
from pathlib import Path
source,target=map(Path,sys.argv[1:3]);prefix=(sys.argv[3] if len(sys.argv)>3 else os.environ['USERPROFILE'])
data=source.read_bytes();assert data[:8]==b'\x00asm\x01\x00\x00\x00'
def sections(b):
 p=8
 while p<len(b):
  ident=b[p];p+=1;n=shift=0
  while True:
   x=b[p];p+=1;n|=(x&127)<<shift
   if not x&128:break
   shift+=7;assert shift<=35
  end=p+n;assert end<=len(b);yield ident,p,end;p=end
before=list(sections(data));out=bytearray(data);changes=[]
for ident,start,end in before:
 segment=data[start:end];count=0
 for pattern in dict.fromkeys([prefix.encode(),prefix.replace(chr(92),'/').encode()]):
  found=segment.count(pattern)
  if found:
   assert ident in [0,11], 'Private path outside metadata/data; refuse to change executable code'
   replacement=b'build-home'.ljust(len(pattern),b'_')[:len(pattern)];segment=segment.replace(pattern,replacement);count+=found
 if count:out[start:end]=segment;changes.append({'section':ident,'replacements':count})
assert len(out)==len(data)
old_code=[hashlib.sha256(data[a:b]).hexdigest() for i,a,b in before if i==10]
new_code=[hashlib.sha256(out[a:b]).hexdigest() for i,a,b in sections(out) if i==10]
assert old_code==new_code and old_code
assert all(p not in out for p in [prefix.encode(),prefix.replace(chr(92),'/').encode()])
if target.exists():raise FileExistsError(target)
target.write_bytes(out)
receipt={'bytes':len(out),'sections':changes,'codeSectionSHA256':new_code,'codeUnchanged':True,'beforeSHA256':hashlib.sha256(data).hexdigest(),'afterSHA256':hashlib.sha256(out).hexdigest()}
target.with_suffix('.receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt))
