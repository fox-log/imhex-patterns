#pragma endian little
#pragma author fox.log
#pragma description Chirp Quansheng uv-k5 image file
#pragma history
#pragma     0.1  2024-12-27  Initial Release

import std.mem;
import std.io;
import type.base64;

bitfield ChannelFlags {
  TxCodeFlag   : 4;
  RxCodeFlag   : 4;
  Unknown1     : 1;
  Unknown2     : 1;
  Unknown3     : 1;
  bool AM      : 1;
  Unknown4     : 1;
  IsInScanlist : 1;
  Shift        : 2;
  Unknown5     : 1;
  Unknown6     : 1;
  Unknown7     : 1;
  BCLO         : 1;
  TxPower      : 2;
  BandWidth    : 1;
  FreqReverse  : 1;
  DTMF1        : 1;
  DTMF2        : 1;
  DTMF3        : 1;
  DTMF4        : 1;
  DTMF5        : 1;
  DTMFPttid    : 2;
  DTMFDecode   : 1;
};

bitfield ChannelAttributes {
  bool Scanlist1 : 1;
  bool Scanlist2 : 1;
  Compander      : 2;
  bool IsFree    : 1;
  Band           : 3;
};

struct Channel {
  u64 start = $;
  u64 channel_num =  start / 16;
  u64 attributes_offset = channel_num + 0x0D60;
  if (std::mem::read_unsigned($,4) == 0xFFFFFFFF) {
    bool empty = true;
    std::mem::Bytes<16> [[hidden]];
    //name
    $ = start + 0x0F50;
    std::mem::Bytes<16> [[hidden]];
    //attributes
    $ = attributes_offset;
    std::mem::Bytes<1> [[hidden]];
  } else {
    bool empty = false;
    u32 Frequency;
    u32 Offset;
    u8 RxCode;
    u8 TxCode;
    ChannelFlags CodeFlags;
    u8 Step;
    u8 Scrambler;
    //name
    $ = start + 0x0F50;
    char Name[while(std::mem::read_unsigned($,1) != 0x00)];
    std::mem::Bytes<16-sizeof(Name)> [[hidden]];
    //attributes
    $ = attributes_offset;
    ChannelAttributes Attributes;
  }
  $ = start + 16;
  std::print("Channel {:03} @ 0x{:04X} {}", channel_num+1, start, empty?"is not set":std::format("is {:.3f} MHz", float(Frequency) / 100000));
} [[single_color]];

struct ExtraChannel {
  u64 channel_num =  ($-0x0C80) / 16;
  if (std::mem::read_unsigned($,4) == 0xFFFFFFFF) {
    bool empty = true;
    std::mem::Bytes<16> [[hidden]];
  } else {
    bool empty = false;
    u32 Frequency;
    u32 Offset;
    u8 RxCode;
    u8 TxCode;
    ChannelFlags CodeFlags;
    u8 Step;
    u8 Scrambler;
  }
  std::print("Extra Channel {:02} @ 0x{:04X} {}", channel_num+1, $-16, empty?"is not set":std::format("is {:.3f} MHz", float(Frequency) / 100000));
};

struct FmChannel {
  u64 channel_num = ($-0x0E40)/2;
  if (std::mem::read_unsigned($, 2) == 0xFFFF) {
    bool empty = true;
    padding[2];
  } else {
    bool empty = false;
    u16 Frequency;
  }
  std::print("Channel {:02} @ 0x{:04X} {}", channel_num+1, $-2, empty?"is not set":std::format("is {:.1f} FM", float(Frequency) / 10));
};

struct DTMFSettings {
  u8 SideTone;
  padding[2];  //dtmf control characters?
  u8 DecodeResponse;
  u8 AutoResetTime;
  u8 PreloadTime;
  u8 FirstCodePersistTime;
  u8 HashPersistTime;
  u8 CodePersistTime;
  u8 CodeIntervalTime;
  u8 PermitRemoteKill;
  padding[5];
  // settings numbers
  char LocalCode[while(std::mem::read_unsigned($,1) != 0x00)];
  padding[8 - sizeof(LocalCode)];
  char KillCode[while(std::mem::read_unsigned($,1) != 0x00)];
  padding[8 - sizeof(KillCode)];
  char ReviveCode[while(std::mem::read_unsigned($,1) != 0x00)];
  padding[8 - sizeof(ReviveCode)];
  char UpCode[while(std::mem::read_unsigned($,1) != 0x00)];
  padding[16 - sizeof(UpCode)];
  char DownCode[while(std::mem::read_unsigned($,1) != 0x00)];
  padding[16 - sizeof(DownCode)];
};

struct DTMFContacts {
  if (std::mem::read_unsigned($,1) == 0x00) {
    padding[8];
  } else {
    char Name[while(std::mem::read_unsigned($,1) != 0x00)];
    padding[8 - sizeof(Name)];
  }
  if (std::mem::read_unsigned($,1) == 0x00 || std::mem::read_unsigned($,1) == 0xFF) {
    padding[8];
  } else {
    char Number[while(std::mem::read_unsigned($,1) != 0x00)];
    padding[8 - sizeof(Number)];
  }
};

struct Locks {
  u8 FLock;
  bool Tx350;
  bool Killed;
  bool Tx200;
  bool Tx500;
  bool En350;
  bool ScrambleEnabled;
};

struct LevelSettings {
  u8 Start;
  u8 Mid;
  u8 End;
};

struct BandPowerSetting {
  LevelSettings Low;
  LevelSettings Medium;
  LevelSettings High;
  padding[7];
};

// Programed Channels
Channel channels[200] @ 0x00 [[name("Channels")]];
ExtraChannel extra_channels[14] @ 0x0C80 [[name("Extra Channels")]];
FmChannel FM_radio[20] @ 0x0E40 [[name("FM Channels")]];

// Settings
DTMFSettings dtmf_settings @ 0x0ED0 [[name("DTMF Settings")]];
DTMFContacts dtmf_contacts[16] @ 0x1c00 [[name("DTMF Contacts")]];
Locks setting_locks @ 0x0F40 [[name("Feature Locks")]];
u8 Password[8] @ 0x0E98;
BandPowerSetting band_power_settings[7] @ 0x1ED0;
u16 battery_level[6] @ 0x1F40;

u8 CallChannel @ 0x0E70;
u8 Squelch @ 0x0E71;
u8 MaxTalkTime @ 0x0E72;
bool NOAAAutoscan @ 0x0E73;
bool KeyLock @ 0x0E74;
bool VoxSwitch @ 0x0E75;
u8 VoxLevel @ 0x0E76;
u8 MicGain @ 0x0E77;
u8 unknown1 @ 0x0E78;
u8 ChannelDisplayMode @ 0x0E79;
bool Crossband @ 0x0E7A;
u8 BatterSave @ 0x0E7B;
u8 DualWatch @ 0x0E7C;
u8 BacklightAutoMode @ 0x0E7D;
bool TailToneElimination @ 0x0E7E;
bool VFOOpen @ 0x0E7F;
bool BeepControl @ 0x0E90;
u8 Key1ShortPress @ 0x0E91;
u8 Key1LongPRess @ 0x0E92;
u8 Key2ShortPress @ 0x0E93;
u8 Key2LongPress @ 0x0E94;
u8 ScanResumeMode @ 0x0E95;
bool AutoKeypadLock @ 0x0E96;
u8 PowerOnDisplayMode @ 0x0E97;
u8 KeypadTone @ 0x0EA0;
u8 Language @ 0x0EA1;
u8 AlarmMode @ 0x0EA8;
bool EndOfTalkReminder @ 0x0EA9;
bool RepeaterTailElimination @ 0x0EAA;

char Logo1[while(std::mem::read_unsigned($,1) != 0x00)] @ 0x0EB0;
char Logo2[while(std::mem::read_unsigned($,1) != 0x00)] @ 0x0EC0;

u8 DefaultScanlist @ 0x0F18;
bool Scanlist1PriorityScan @ 0x0F19;
u8 Scanlist1Priority1 @ 0x0F1A;
u8 Scalist1Priority2 @ 0x0F1B;
bool Scanlist2PriorityScan @ 0x0F1C;
u8 Scanlist2Priority1 @ 0x0F1D;
u8 Scalist2Priority2 @ 0x0F1E;

char ChirpData1[5] @ 0x2002;
char ChirpData2[3] @ 0x2008;
char ChirpData3[std::mem::size()-0x200D] @ 0x200D [[transform("type::impl::decode_base64"), format("type::impl::decode_base64")]];
