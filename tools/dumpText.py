import sys
import StringIO

index = sys.argv[0].find('/')
if index == -1:
    directory = ''
else:
    directory = sys.argv[0][:index+1]
execfile(directory+'common.py')

if len(sys.argv) < 2:
    print 'Usage: ' + sys.argv[0] + ' romfile'
    sys.exit()

romFile = open(sys.argv[1], 'rb')
rom = bytearray(romFile.read())


class HighIndexStruct:

    def __init__(self):
        self.address = -1
        self.indices = []
        self.size = -1


class TextStruct:

    def __init__(self):
        self.data = None
        self.index = -1  # "Main" index
        self.indices = []  # List of all actual indices
        self.address = -1

textTableOutput = StringIO.StringIO()
textDataOutput = StringIO.StringIO()
dictDataOutput = StringIO.StringIO()

# Constants
textTable = 0x74000
textTableBank = 0x1d
numHighTextIndices = 0x64

# Indices under 2c
textBase1 = 0x75ed8
# Indices 2c and above
textBase2 = 0x8458e

highIndexList = []

textTableOutput.write('textTableENG:\n')
for i in xrange(0, numHighTextIndices):
    textTableOutput.write(
        '\t.dw textTableENG_' + myhex(i, 2) + ' - textTableENG\n')

    address = textTable+read16(rom, textTable+i*2)
    data = None
    for d in highIndexList:
        if d.address == address:
            data = d
            break
    if data is None:
        data = HighIndexStruct()
        data.address = address
        data.indices = [i]
        highIndexList.append(data)
    else:
        data.indices.append(i)
    lastAddress = address

highIndexList = sorted(highIndexList, key=lambda d: d.address)

# First pass through address-sorted tables: calculate table sizes
for i in xrange(len(highIndexList)):
    data = highIndexList[i]
    if i != 0:
        highIndexList[i-1].size = (data.address - highIndexList[i-1].address)/2

# Size of last one must be hard-coded
highIndexList[len(highIndexList)-1].size = 0x16

textAddressList = set()
textAddressDictionary = {}
textIndexDictionary = {}
textList = set()

lastAddress = 0
# Second pass, print stuff out and get list of text addresses
for i in xrange(len(highIndexList)):
    data = highIndexList[i]

    if lastAddress != data.address and i != 0:
        textTableOutput.write('; Address mismatch\n')
    for index in data.indices:
        textTableOutput.write(
            'textTableENG_' + myhex(index, 2) + ': ; ' + wlahex(data.address, 4) + '\n')
    for index in xrange(data.size):
        addr = data.address + index*2
        textAddress = read16(rom, addr)

        if data.indices[0] < 0x2c:
            textAddress += textBase1
        else:
            textAddress += textBase2
        textAddressList.add(textAddress)

        textStruct = textAddressDictionary.get(textAddress)
        if textStruct is None:
            textStruct = TextStruct()
            textStruct.address = textAddress
            textStruct.index = ((data.indices[0]<<8)|index)
            textAddressDictionary[textAddress] = textStruct
            textIndexDictionary[textStruct.index] = textStruct
            textList.add(textStruct)
        textStruct.indices.append((data.indices[0]<<8)|index)

        textTableOutput.write('\tm_TextPointer text_' + myhex(textAddress, 4))
        if data.indices[0] < 0x2c:
            textBase = textBase1
        else:
            textBase = textBase2
        textTableOutput.write(
            ' ' + wlahex(textBase/0x4000, 2) + ' ' + wlahex(textBase&0x3fff, 4) + '\n')

    lastAddress = data.address + data.size*2


def getTextDecompressed(out, address, end=-1):
    if end == -1:
        end = 0x100000000
    i = address
    while i < end:
        b = rom[i]
        if b >= 2 and b < 6 and end-i >= 2:
            dictAddress = textIndexDictionary[((b-2)<<8) | rom[i+1]].address
            getTextDecompressed(out, dictAddress)
            i+=1
        elif b >= 0x6 and b < 0x10:
            data.append(b)
            data.append(rom[i+1])
            i+=1
        else:
            if b == 0:
                if end != 0x100000000:  # Not parsing a dictionary
                    data.append(b)
                break
            data.append(b)
        i += 1

definesFile = open('precompressed/textDefines.s','w')

definesFile.write('.define TEXT_OFFSET_SPLIT_INDEX $2c\n\n')

# Now pass through the text addresses themselves, start dumping
address = 0x75ed8
while address < 0x8e7e3:
    pos = address
    while rom[pos] != 0:
        c = rom[pos]
        pos+=1

        # Special cases (don't have preceding null terminators)
        if textAddressDictionary.get(pos+1) is not None:
            break

        if c >= 0x2 and c < 0x10:
            pos+=1

        # Special cases (don't have preceding null terminators)
        if textAddressDictionary.get(pos+1) is not None:
            break
    pos+=1
    textStruct = textAddressDictionary.get(address)
    if textStruct is None:
        print 'text_' + myhex(address, 2) + ' is never referenced'
        print 'Output may be malformed'
        out = textDataOutput
    else:
        index = textStruct.index
        if index < 0x400:
            dataOut = dictDataOutput
            dataOut.write('\\name(DICT' + myhex(index>>8, 1) + '_'
                                 + myhex(index&0xff, 2) + ')\n')
        else:
            dataOut = textDataOutput
            dataOut.write('\\name(TX_' + myhex(index-0x400, 4) + ')\n')
            definesFile.write('.define TX_' + myhex(index-0x400,4) + ' ' + wlahex(index-0x400,4) + '\n')

    dataOut.write('\\start\n')

    data = bytearray()
    getTextDecompressed(data, address, pos)
    i = 0
    while i < len(data):
        b = data[i]
        if (b >= 0x20 and b < 0x80):
            dataOut.write(chr(b))
        elif b == 0x1:
            dataOut.write('\n')
        elif b == 0x6 and len(data)>i+1:
            p = data[i+1]
            if p&0x80 == 0x80:
                dataOut.write('\\item(' + wlahex(p&0x7f,2) + ')')
            else:
                dataOut.write('\\sym(' + wlahex(p&0x7f,2) + ')')
            i+=1
        elif b == 0x7 and len(data)>i+1:
            dataOut.write('\\jump(' + wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == 0x9 and len(data)>i+1:
            if data[i+1] < 0x80:
                dataOut.write('\\col(' + str(data[i+1]) + ')')
            else:
                dataOut.write('\\col(' + wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == 0xa and len(data)>i+1:
            if data[i+1] == 0:
                dataOut.write('\\Link')
                i+=1
            elif data[i+1] == 0x1:
                dataOut.write('\\kidname')
                i+=1
            elif data[i+1] == 0x2:
                dataOut.write('\\secret1')
                i+=1
            elif data[i+1] == 0x3:
                dataOut.write('\\secret2')
                i+=1
            else:
                dataOut.write('\\' + myhex(b, 2))
        elif b == 0xb and len(data)>i+1:
            dataOut.write('\\charsfx(' + wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == 0xc and len(data)>i+1:
            p = data[i+1]>>3
            c = data[i+1]&3
            if p == 0:
                dataOut.write('\\speed(' + str(c) + ')')
            elif p == 1:
                dataOut.write('\\number')
            elif p == 2:
                dataOut.write('\\opt()')
            elif p == 3:
                dataOut.write('\\stop')
            elif p == 4:
                dataOut.write('\\pos(' + str(c) + ')')
            elif p == 5:
                dataOut.write('\\heartpiece')
            elif p == 6:
                dataOut.write('\\num2') # This doesn't show up in ages... maybe in seasons
            elif p == 7:
                dataOut.write('\\slow()')
            else:
                print 'Bad opcode'
            i+=1
        elif b == 0xd and len(data)>i+1:
            dataOut.write('\\wait(' + wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == 0xe and len(data)>i+1:
            dataOut.write('\\sfx(' + wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == 0xf and len(data)>i+1:
            p=data[i+1]
            dataOut.write('\\call(' + wlahex(p,2) + ')')
            i+=1
        elif b >= 0x6 and b < 0x10:
            dataOut.write('\\cmd' + myhex(b, 1) + '(' +
                                 wlahex(data[i+1], 2) + ')')
            i+=1
        elif b == '\\':
            dataOut.write('\\\\')
        elif b == 0x10:
            dataOut.write('\\circle')
        elif b == 0x11:
            dataOut.write('\\club')
        elif b == 0x12:
            dataOut.write('\\diamond')
        elif b == 0x13:
            dataOut.write('\\spade')
        elif b == 0x14:
            dataOut.write('\\heart')
        elif b == 0x15:
            dataOut.write('\\up')
        elif b == 0x16:
            dataOut.write('\\down')
        elif b == 0x17:
            dataOut.write('\\left')
        elif b == 0x18:
            dataOut.write('\\right')
        elif b == 0xb8 and len(data)>i+1 and data[i+1] == 0xb9:
            dataOut.write('\\abtn')
            i+=1
        elif b == 0xba and len(data)>i+1 and data[i+1] == 0xbb:
            dataOut.write('\\bbtn')
            i+=1
        elif b == 0x7e:
            dataOut.write('\\triangle')
        elif b == 0x7f:
            dataOut.write('\\rectangle')
        else:
            if not (b == 0 and i == len(data)-1):
                dataOut.write('\\' + myhex(b, 2))
        i+=1
    if data[len(data)-1] != 0:
        dataOut.write('\n\\endwithoutnull\n')
    else:
        dataOut.write('\n\\end\n')

    textStruct.data = data

    for i in sorted(textStruct.indices):  # Handle extra indices with 'stubs'
        if i != index:
            if index+1 == i:
                dataOut.write('\\next\n\n')
            else:
                dataOut.write('\\next(' + wlahex(i-0x400, 4) + ')\n')
            index = i

    address = pos

    nextTextStruct = textAddressDictionary.get(address)
    if nextTextStruct is not None:
        nextIndex = nextTextStruct.index
        if (index>>8)+1 == (nextIndex>>8) and (nextIndex&0xff) == 0:
            dataOut.write('\\nextgroup\n')
        elif index+1 == nextIndex:
            dataOut.write('\\next\n')
        else:
            dataOut.write('\\next(' + wlahex(nextIndex-0x400, 4) + ')\n')
    dataOut.write('\n')
    # print '\rpos ' + hex(pos),

definesFile.close()

outFile = open('text/dict.txt', 'w')
dictDataOutput.seek(0)
outFile.write(dictDataOutput.read())
outFile.close()

outFile = open('text/text.txt', 'w')
textDataOutput.seek(0)
outFile.write(textDataOutput.read())
outFile.close()

# Debug output

#outFile = open('text/text_blob_decompressed.bin','w')
#lastAddress = -1
# for address in sorted(textAddressList):
#        if address < lastAddress:
#            print 'BAD'
#        lastAddress = address
#        textStruct = textAddressDictionary[address]
#        if textStruct.data is None:
#                print 'Index ' + hex(textStruct.index) + ' uninitialized'
#        else:
#                outFile.write(textStruct.data)
# outFile.close()
