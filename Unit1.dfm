object ConectLabMobile64: TConectLabMobile64
  OldCreateOrder = False
  Dependencies = <
    item
      Name = 'MySQL'
      IsGroup = False
    end>
  DisplayName = 'Service1'
  Interactive = True
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
