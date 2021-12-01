pragma Ada_2012;
pragma Style_Checks (Off);
pragma Warnings ("U");

with Interfaces.C; use Interfaces.C;
with sys_ustdint_h;
with vl53l1_platform_h;

package VL53L1X_api_h is

   VL53L1X_IMPLEMENTATION_VER_MAJOR : constant := 3;  --  ../core/VL53L1X_api.h:78
   VL53L1X_IMPLEMENTATION_VER_MINOR : constant := 5;  --  ../core/VL53L1X_api.h:79
   VL53L1X_IMPLEMENTATION_VER_SUB : constant := 1;  --  ../core/VL53L1X_api.h:80
   VL53L1X_IMPLEMENTATION_VER_REVISION : constant := 8#000#;  --  ../core/VL53L1X_api.h:81

   SOFT_RESET : constant := 16#0000#;  --  ../core/VL53L1X_api.h:85
   VL53L1_I2C_SLAVE_u_DEVICE_ADDRESS : constant := 16#0001#;  --  ../core/VL53L1X_api.h:86
   VL53L1_VHV_CONFIG_u_TIMEOUT_MACROP_LOOP_BOUND : constant := 16#0008#;  --  ../core/VL53L1X_api.h:87
   ALGO_u_CROSSTALK_COMPENSATION_PLANE_OFFSET_KCPS : constant := 16#0016#;  --  ../core/VL53L1X_api.h:88
   ALGO_u_CROSSTALK_COMPENSATION_X_PLANE_GRADIENT_KCPS : constant := 16#0018#;  --  ../core/VL53L1X_api.h:89
   ALGO_u_CROSSTALK_COMPENSATION_Y_PLANE_GRADIENT_KCPS : constant := 16#001A#;  --  ../core/VL53L1X_api.h:90
   ALGO_u_PART_TO_PART_RANGE_OFFSET_MM : constant := 16#001E#;  --  ../core/VL53L1X_api.h:91
   MM_CONFIG_u_INNER_OFFSET_MM : constant := 16#0020#;  --  ../core/VL53L1X_api.h:92
   MM_CONFIG_u_OUTER_OFFSET_MM : constant := 16#0022#;  --  ../core/VL53L1X_api.h:93
   GPIO_HV_MUX_u_CTRL : constant := 16#0030#;  --  ../core/VL53L1X_api.h:94
   GPIO_u_TIO_HV_STATUS : constant := 16#0031#;  --  ../core/VL53L1X_api.h:95
   SYSTEM_u_INTERRUPT_CONFIG_GPIO : constant := 16#0046#;  --  ../core/VL53L1X_api.h:96
   PHASECAL_CONFIG_u_TIMEOUT_MACROP : constant := 16#004B#;  --  ../core/VL53L1X_api.h:97
   RANGE_CONFIG_u_TIMEOUT_MACROP_A_HI : constant := 16#005E#;  --  ../core/VL53L1X_api.h:98
   RANGE_CONFIG_u_VCSEL_PERIOD_A : constant := 16#0060#;  --  ../core/VL53L1X_api.h:99
   RANGE_CONFIG_u_VCSEL_PERIOD_B : constant := 16#0063#;  --  ../core/VL53L1X_api.h:100
   RANGE_CONFIG_u_TIMEOUT_MACROP_B_HI : constant := 16#0061#;  --  ../core/VL53L1X_api.h:101
   RANGE_CONFIG_u_TIMEOUT_MACROP_B_LO : constant := 16#0062#;  --  ../core/VL53L1X_api.h:102
   RANGE_CONFIG_u_SIGMA_THRESH : constant := 16#0064#;  --  ../core/VL53L1X_api.h:103
   RANGE_CONFIG_u_MIN_COUNT_RATE_RTN_LIMIT_MCPS : constant := 16#0066#;  --  ../core/VL53L1X_api.h:104
   RANGE_CONFIG_u_VALID_PHASE_HIGH : constant := 16#0069#;  --  ../core/VL53L1X_api.h:105
   VL53L1_SYSTEM_u_INTERMEASUREMENT_PERIOD : constant := 16#006C#;  --  ../core/VL53L1X_api.h:106
   SYSTEM_u_THRESH_HIGH : constant := 16#0072#;  --  ../core/VL53L1X_api.h:107
   SYSTEM_u_THRESH_LOW : constant := 16#0074#;  --  ../core/VL53L1X_api.h:108
   SD_CONFIG_u_WOI_SD0 : constant := 16#0078#;  --  ../core/VL53L1X_api.h:109
   SD_CONFIG_u_INITIAL_PHASE_SD0 : constant := 16#007A#;  --  ../core/VL53L1X_api.h:110
   ROI_CONFIG_u_USER_ROI_CENTRE_SPAD : constant := 16#007F#;  --  ../core/VL53L1X_api.h:111
   ROI_CONFIG_u_USER_ROI_REQUESTED_GLOBAL_XY_SIZE : constant := 16#0080#;  --  ../core/VL53L1X_api.h:112
   SYSTEM_u_SEQUENCE_CONFIG : constant := 16#0081#;  --  ../core/VL53L1X_api.h:113
   VL53L1_SYSTEM_u_GROUPED_PARAMETER_HOLD : constant := 16#0082#;  --  ../core/VL53L1X_api.h:114
   SYSTEM_u_INTERRUPT_CLEAR : constant := 16#0086#;  --  ../core/VL53L1X_api.h:115
   SYSTEM_u_MODE_START : constant := 16#0087#;  --  ../core/VL53L1X_api.h:116
   VL53L1_RESULT_u_RANGE_STATUS : constant := 16#0089#;  --  ../core/VL53L1X_api.h:117
   VL53L1_RESULT_u_DSS_ACTUAL_EFFECTIVE_SPADS_SD0 : constant := 16#008C#;  --  ../core/VL53L1X_api.h:118
   RESULT_u_AMBIENT_COUNT_RATE_MCPS_SD : constant := 16#0090#;  --  ../core/VL53L1X_api.h:119
   VL53L1_RESULT_u_FINAL_CROSSTALK_CORRECTED_RANGE_MM_SD0 : constant := 16#0096#;  --  ../core/VL53L1X_api.h:120
   VL53L1_RESULT_u_PEAK_SIGNAL_COUNT_RATE_CROSSTALK_CORRECTED_MCPS_SD0 : constant := 16#0098#;  --  ../core/VL53L1X_api.h:121
   VL53L1_RESULT_u_OSC_CALIBRATE_VAL : constant := 16#00DE#;  --  ../core/VL53L1X_api.h:122
   VL53L1_FIRMWARE_u_SYSTEM_STATUS : constant := 16#00E5#;  --  ../core/VL53L1X_api.h:123
   VL53L1_IDENTIFICATION_u_MODEL_ID : constant := 16#010F#;  --  ../core/VL53L1X_api.h:124
   VL53L1_ROI_CONFIG_u_MODE_ROI_CENTRE_SPAD : constant := 16#013E#;  --  ../core/VL53L1X_api.h:125

   subtype VL53L1X_ERROR is sys_ustdint_h.int8_t;  -- ../core/VL53L1X_api.h:83

   --  skipped anonymous struct anon_anon_2

   type VL53L1X_Version_t is record
      major : aliased sys_ustdint_h.uint8_t;  -- ../core/VL53L1X_api.h:135
      minor : aliased sys_ustdint_h.uint8_t;  -- ../core/VL53L1X_api.h:136
      build : aliased sys_ustdint_h.uint8_t;  -- ../core/VL53L1X_api.h:137
      revision : aliased sys_ustdint_h.uint32_t;  -- ../core/VL53L1X_api.h:138
   end record
   with Convention => C_Pass_By_Copy;  -- ../core/VL53L1X_api.h:139

   --  skipped anonymous struct anon_anon_3

   type VL53L1X_Result_t is record
      Status : aliased sys_ustdint_h.uint8_t;  -- ../core/VL53L1X_api.h:145
      Distance : aliased sys_ustdint_h.uint16_t;  -- ../core/VL53L1X_api.h:146
      Ambient : aliased sys_ustdint_h.uint16_t;  -- ../core/VL53L1X_api.h:147
      SigPerSPAD : aliased sys_ustdint_h.uint16_t;  -- ../core/VL53L1X_api.h:148
      NumSPADs : aliased sys_ustdint_h.uint16_t;  -- ../core/VL53L1X_api.h:149
   end record
   with Convention => C_Pass_By_Copy;  -- ../core/VL53L1X_api.h:150

   function VL53L1X_GetSWVersion (pVersion : access VL53L1X_Version_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:155
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSWVersion";

   function VL53L1X_SetI2CAddress (dev : vl53l1_platform_h.VL53L1_DEV; new_address : sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:160
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetI2CAddress";

   function VL53L1X_SensorInit (dev : vl53l1_platform_h.VL53L1_DEV) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:167
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SensorInit";

   function VL53L1X_ClearInterrupt (dev : vl53l1_platform_h.VL53L1_DEV) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:173
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_ClearInterrupt";

   function VL53L1X_SetInterruptPolarity (dev : vl53l1_platform_h.VL53L1_DEV; IntPol : sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:179
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetInterruptPolarity";

   function VL53L1X_GetInterruptPolarity (dev : vl53l1_platform_h.VL53L1_DEV; pIntPol : access sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:185
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetInterruptPolarity";

   function VL53L1X_StartRanging (dev : vl53l1_platform_h.VL53L1_DEV) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:192
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_StartRanging";

   function VL53L1X_StopRanging (dev : vl53l1_platform_h.VL53L1_DEV) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:197
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_StopRanging";

   function VL53L1X_CheckForDataReady (dev : vl53l1_platform_h.VL53L1_DEV; isDataReady : access sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:203
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_CheckForDataReady";

   function VL53L1X_SetTimingBudgetInMs (dev : vl53l1_platform_h.VL53L1_DEV; TimingBudgetInMs : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:209
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetTimingBudgetInMs";

   function VL53L1X_GetTimingBudgetInMs (dev : vl53l1_platform_h.VL53L1_DEV; pTimingBudgetInMs : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:214
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetTimingBudgetInMs";

   function VL53L1X_SetDistanceMode (dev : vl53l1_platform_h.VL53L1_DEV; DistanceMode : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:221
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetDistanceMode";

   function VL53L1X_GetDistanceMode (dev : vl53l1_platform_h.VL53L1_DEV; pDistanceMode : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:226
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetDistanceMode";

   function VL53L1X_SetInterMeasurementInMs (dev : vl53l1_platform_h.VL53L1_DEV; InterMeasurementInMs : sys_ustdint_h.uint32_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:233
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetInterMeasurementInMs";

   function VL53L1X_GetInterMeasurementInMs (dev : vl53l1_platform_h.VL53L1_DEV; pIM : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:239
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetInterMeasurementInMs";

   function VL53L1X_BootState (dev : vl53l1_platform_h.VL53L1_DEV; state : access sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:244
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_BootState";

   function VL53L1X_GetSensorId (dev : vl53l1_platform_h.VL53L1_DEV; id : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:249
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSensorId";

   function VL53L1X_GetDistance (dev : vl53l1_platform_h.VL53L1_DEV; distance : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:254
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetDistance";

   function VL53L1X_GetSignalPerSpad (dev : vl53l1_platform_h.VL53L1_DEV; signalPerSp : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:260
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSignalPerSpad";

   function VL53L1X_GetAmbientPerSpad (dev : vl53l1_platform_h.VL53L1_DEV; amb : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:265
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetAmbientPerSpad";

   function VL53L1X_GetSignalRate (dev : vl53l1_platform_h.VL53L1_DEV; signalRate : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:270
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSignalRate";

   function VL53L1X_GetSpadNb (dev : vl53l1_platform_h.VL53L1_DEV; spNb : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:275
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSpadNb";

   function VL53L1X_GetAmbientRate (dev : vl53l1_platform_h.VL53L1_DEV; ambRate : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:280
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetAmbientRate";

   function VL53L1X_GetRangeStatus (dev : vl53l1_platform_h.VL53L1_DEV; rangeStatus : access sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:286
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetRangeStatus";

   function VL53L1X_GetResult (dev : vl53l1_platform_h.VL53L1_DEV; pResult : access VL53L1X_Result_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:291
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetResult";

   function VL53L1X_SetOffset (dev : vl53l1_platform_h.VL53L1_DEV; OffsetValue : sys_ustdint_h.int16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:297
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetOffset";

   function VL53L1X_GetOffset (dev : vl53l1_platform_h.VL53L1_DEV; Offset : access sys_ustdint_h.int16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:302
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetOffset";

   function VL53L1X_SetXtalk (dev : vl53l1_platform_h.VL53L1_DEV; XtalkValue : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:308
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetXtalk";

   function VL53L1X_GetXtalk (dev : vl53l1_platform_h.VL53L1_DEV; Xtalk : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:313
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetXtalk";

   function VL53L1X_SetDistanceThreshold
     (dev : vl53l1_platform_h.VL53L1_DEV;
      ThreshLow : sys_ustdint_h.uint16_t;
      ThreshHigh : sys_ustdint_h.uint16_t;
      Window : sys_ustdint_h.uint8_t;
      IntOnNoTarget : sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:328
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetDistanceThreshold";

   function VL53L1X_GetDistanceThresholdWindow (dev : vl53l1_platform_h.VL53L1_DEV; window : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:335
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetDistanceThresholdWindow";

   function VL53L1X_GetDistanceThresholdLow (dev : vl53l1_platform_h.VL53L1_DEV; low : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:340
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetDistanceThresholdLow";

   function VL53L1X_GetDistanceThresholdHigh (dev : vl53l1_platform_h.VL53L1_DEV; high : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:345
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetDistanceThresholdHigh";

   function VL53L1X_SetROI
     (dev : vl53l1_platform_h.VL53L1_DEV;
      X : sys_ustdint_h.uint16_t;
      Y : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:353
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetROI";

   function VL53L1X_GetROI_XY
     (dev : vl53l1_platform_h.VL53L1_DEV;
      ROI_X : access sys_ustdint_h.uint16_t;
      ROI_Y : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:358
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetROI_XY";

   function VL53L1X_SetROICenter (dev : vl53l1_platform_h.VL53L1_DEV; ROICenter : sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:364
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetROICenter";

   function VL53L1X_GetROICenter (dev : vl53l1_platform_h.VL53L1_DEV; ROICenter : access sys_ustdint_h.uint8_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:369
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetROICenter";

   function VL53L1X_SetSignalThreshold (dev : vl53l1_platform_h.VL53L1_DEV; signal : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:374
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetSignalThreshold";

   function VL53L1X_GetSignalThreshold (dev : vl53l1_platform_h.VL53L1_DEV; signal : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:379
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSignalThreshold";

   function VL53L1X_SetSigmaThreshold (dev : vl53l1_platform_h.VL53L1_DEV; sigma : sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:384
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_SetSigmaThreshold";

   function VL53L1X_GetSigmaThreshold (dev : vl53l1_platform_h.VL53L1_DEV; signal : access sys_ustdint_h.uint16_t) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:389
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_GetSigmaThreshold";

   function VL53L1X_StartTemperatureUpdate (dev : vl53l1_platform_h.VL53L1_DEV) return VL53L1X_ERROR  -- ../core/VL53L1X_api.h:396
   with Import => True, 
        Convention => C, 
        External_Name => "VL53L1X_StartTemperatureUpdate";

end VL53L1X_api_h;
