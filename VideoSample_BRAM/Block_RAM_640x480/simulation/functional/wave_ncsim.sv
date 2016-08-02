

 
 
 

 



window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"

      waveform add -signals /Block_RAM_640x480_tb/status
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/RSTA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/CLKA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/ADDRA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/DINA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/WEA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/ENA
      waveform add -signals /Block_RAM_640x480_tb/Block_RAM_640x480_synth_inst/bmg_port/DOUTA

console submit -using simulator -wait no "run"
