"""Isolated Ruffle 0.7.1 scheduler experiment; preserve its authored frame duration.

Add a bounded comparison tolerance to the frame accumulator, while still
subtracting the exact original frame duration. This changes dispatch timing,
not the game's average rate. Inputs must match a supplied SHA-256.
"""
from pathlib import Path
import argparse,hashlib,json,re,struct,subprocess

def leb(value):
    out=bytearray()
    while True:
        byte=value&127;value>>=7;out.append(byte|(128 if value else 0))
        if not value:return bytes(out)

def read_leb(data,pos):
    value=shift=0
    while True:
        byte=data[pos];pos+=1;value|=(byte&127)<<shift;shift+=7
        if not byte&128:return value,pos

def string(data,pos):
    size,pos=read_leb(data,pos)
    return data[pos:pos+size].decode('utf8'),pos+size

def sections(data):
    pos=8
    while pos<len(data):
        kind=data[pos];sizepos=pos+1;size,start=read_leb(data,sizepos);end=start+size
        yield kind,sizepos,start,end
        pos=end

def scheduler_index(data):
    found=[]
    for kind,_,start,end in sections(data):
        if kind:continue
        name,pos=string(data,start)
        if name!='name':continue
        while pos<end:
            sub=data[pos];size,pos=read_leb(data,pos+1);subend=pos+size
            if sub==1:
                count,pos=read_leb(data,pos)
                for _ in range(count):
                    index,pos=read_leb(data,pos);name,pos=string(data,pos)
                    if re.fullmatch(r'<ruffle_core\[.*\]::player::Player>::tick',name):found.append(index)
            pos=subend
    if len(found)!=1:raise ValueError('Expected exactly one named Ruffle scheduler.')
    return found[0]

def inspect(tool,source,index):
    proc=subprocess.Popen([str(tool),'print','-p','--name-unnamed',str(source)],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,encoding='utf8')
    lines=[];active=False
    try:
        for line in proc.stdout:
            match=re.search(r'\(func .*?\(;(\d+);\)',line)
            if match:
                if active:break
                if int(match[1])==index:active=True
            if active:lines.append(line)
    finally:
        proc.stdout.close()
        if proc.poll() is None:proc.terminate()
        proc.wait()
    rows=[]
    for line in lines:
        match=re.match(r'\(;@([a-fA-F0-9]+);\)\s+(.*)',line)
        if match:rows.append((int(match[1],16),match[2].strip()))
    candidates=[]
    for i in range(len(rows)-3):
        ops=[x[1] for x in rows[i:i+4]]
        if ops[0].startswith('local.tee ') and ops[1].startswith('local.get ') and ops[2:] == ['f64.le','i32.eqz']:
            previous='\n'.join(x[1] for x in rows[max(0,i-30):i])
            if '(;=1000;)' in previous and 'f64.store offset=328' in previous:
                candidates.append((i,ops[0].split()[1],ops[1].split()[1]))
    if len(candidates)!=1:raise ValueError('Scheduler entry comparison is not uniquely recognized.')
    i,duration,accumulator=candidates[0]
    loops=[]
    for j in range(len(rows)-3):
        ops=[x[1] for x in rows[j:j+4]]
        if ops[:3]==['local.get '+accumulator,'local.get '+duration,'f64.ge'] and ops[3].startswith('br_if '):loops.append(j)
    if len(loops)!=1:raise ValueError('Scheduler loop comparison is not uniquely recognized.')
    return [rows[i+2][0],rows[loops[0]+1][0]]

def patch(data,positions,epsilon):
    # f64.const epsilon; f64.add. Both locations have the accumulator atop the
    # operand stack. No function indices, imports, exports or rendering code change.
    addition=b'\x44'+struct.pack('<d',epsilon)+b'\xa0'
    if data[positions[0]]!=0x65 or data[positions[1]]!=0x20:raise ValueError('Unexpected comparison bytecode.')
    matches=[]
    for kind,sizepos,start,end in sections(data):
        if kind!=10:continue
        count,pos=read_leb(data,start)
        for _ in range(count):
            lengthpos=pos;length,bodypos=read_leb(data,pos);bodyend=bodypos+length
            if all(bodypos<=x<bodyend for x in positions):
                body=data[bodypos:bodyend]
                for absolute in sorted(positions,reverse=True):
                    offset=absolute-bodypos;body=body[:offset]+addition+body[offset:]
                payload=data[start:lengthpos]+leb(len(body))+body+data[bodyend:end]
                matches.append(data[:sizepos]+leb(len(payload))+payload+data[end:])
            pos=bodyend
    if len(matches)!=1:raise ValueError('Comparison edits do not lie in a single code body.')
    return matches[0]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path);parser.add_argument('output',type=Path)
    parser.add_argument('--wasm-tools',required=True,type=Path)
    parser.add_argument('--expect-sha256',required=True)
    parser.add_argument('--epsilon-ms',type=float,default=.5)
    args=parser.parse_args()
    if not 0<args.epsilon_ms<=.5:raise ValueError('Only bounded tolerances up to 0.5ms are accepted.')
    data=args.source.read_bytes();before=hashlib.sha256(data).hexdigest()
    if before!=args.expect_sha256.lower():raise ValueError('Source SHA-256 mismatch; no output written.')
    index=scheduler_index(data);positions=inspect(args.wasm_tools,args.source,index)
    result=patch(data,positions,args.epsilon_ms)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_bytes(result)
    subprocess.run([str(args.wasm_tools),'validate',str(args.output)],check=True)
    manifest={'sourceCommit':'89a7049965f3090e706265670df309a5128233ac','source':args.source.name,'sourceSha256':before,'outputSha256':hashlib.sha256(result).hexdigest(),'functionIndex':index,'insertionOffsets':positions,'epsilonMs':args.epsilon_ms,'byteDelta':len(result)-len(data)}
    args.output.with_suffix('.pacing.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps(manifest))

if __name__=='__main__':main()
