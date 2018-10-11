SELECT DISTINCT
  SPatient.PatientSID
  ,SPatient.PatientSSN
  ,SPatient.Sta3n
  ,SPatient.PatientName
  ,SPatient.Age
  ,SPatient.Gender
  ,Ward.WardLocationName
  ,Bed.RoomBed
  ,HFT.HealthFactorType
  ,Inpatient.AdmitDateTime
  ,HF.HealthFactorDateTime
  ,Microbiology.SpecimenTakenDateTime
  ,Inpatient.DischargeDateTime
  ,MicroBiology.RequestingWard
  ,MicroBiology.SpecimenComment
  ,DimCollectionSample.CollectionSample
  ,AntiSens.OrganismQuantity
  ,AntiSens.AntibioticSensitivityValue
  ,AntiSensComm.AntibioticSensitivityComments
  ,DimAntibiotic.Antibiotic
  ,DimAntibiotic.DrugNodeIEN
  ,DimAntibiotic.AntibioticDisplayComment
  ,DimAntibiotic.LabProcedure
  ,DimOrganism.Organism
  ,DimOrganism.OrganismCategory
  ,DimOrganism.GramStain
  ,SAddress.City AS PatientCity
  ,SAddress.County AS PatientCounty
  ,SAddress.State AS PatientState
  ,SAddress.Zip AS PatientZip
  ,SAddress.Zip4 AS PatientZip4
  ,SAddress.GISPatientAddressLongitude AS PatientLON
  ,SAddress.GISPatientAddressLatitude AS PatientLAT
  ,SAddress.GISFIPSCode AS PatientFIPS
  ,SAddress.GISMarket AS PatientMarket
  ,SAddress.GISSubmarket AS PatientSubmarket
  ,CASE WHEN AntiSens.OrganismQuantity IS NOT NULL
    THEN 1 ELSE 0 END AS Growth
  ,CASE WHEN HF.healthfactorDateTime > Inpatient.AdmitDateTime 
    AND (HF.healthfactorDateTime < Inpatient.DischargeDateTime OR Inpatient.DischargeDateTime IS NULL)
	THEN 1 ELSE 0 END AS Inpatient
  ,CASE WHEN HFT.HealthFactorType LIKE '%LINE NEW%'
    THEN HF.HealthFactorDateTime ELSE NULL END AS LineNew
  ,CASE WHEN HFT.HealthFactorType LIKE '%SITE STATUS%'
    THEN HF.HealthFactorDateTime ELSE NULL END AS LineStatus
  ,CASE WHEN HFT.HealthFactorType LIKE '%LINE LOC%'
    THEN HFT.HealthFactorType ELSE NULL END AS LineLoc
  ,CASE WHEN HFT.HealthFactorType LIKE '%REMOVE%'
    THEN HFT.HealthFactorType ELSE NULL END AS LineRemoved
	
FROM
  LSV.SPatient.SPatientAddress AS SAddress
  INNER JOIN LSV.BISL_R1VX.AR3Y_SPatient_SPatient AS SPatient
    ON SAddress.PatientSID = SPatient.PatientSID
	AND SPatient.Sta3n = '612'

  INNER JOIN LSV.BISL_R1VX.AR3Y_HF_HealthFactor AS HF
    ON SPatient.PatientSID = HF.PatientSID
	AND SPatient.Sta3n = '612'
  LEFT JOIN LSV.Dim.HealthFactorType AS HFT
    ON HF.HEalthFactorTypeSID = HFT.HealthfactorTypeSID
	AND HF.Sta3n = '612'

  LEFT JOIN LSV.Micro.Microbiology AS Microbiology
    ON SPatient.PatientSID = Microbiology.PatientSID 
	AND Microbiology.Sta3n = '612'
  LEFT JOIN LSV.Dim.CollectionSample AS DimCollectionSample
    ON Microbiology.CollectionSampleSID = DimCollectionSample.CollectionSampleSID 
	AND DimCollectionSample.Sta3n = '612'
  LEFT JOIN LSV.Micro.AntibioticSensitivity AS AntiSens
    ON Microbiology.MicrobiologySID = AntiSens.MicrobiologySID 
	AND AntiSens.Sta3n = '612'
  LEFT JOIN LSV.Micro.AntibioticSensitivityComment AS AntiSensComm
    ON AntiSens.MicroBiologySID = AntiSensComm.MicroBiologySID
	AND AntiSensComm.Sta3n = '612'
  LEFT JOIN LSV.Dim.Antibiotic AS DimAntibiotic
    ON AntiSens.AntibioticSID = DimAntibiotic.AntibioticSID
	AND DimAntibiotic.Sta3n = '612'
  LEFT JOIN LSV.Dim.Organism AS DimOrganism
    ON AntiSens.OrganismSID = DimOrganism.OrganismSID
	AND DimOrganism.Sta3n = '612'

  LEFT JOIN LSV.BISL_R1VX.AR3Y_Inpat_Inpatient AS Inpatient
    ON SPatient.PatientSID = Inpatient.PatientSID
	AND Inpatient.Sta3n = '612'
  LEFT JOIN LSV.Dim.WardLocation AS Ward
    ON Inpatient.AdmitWardLocationSID = Ward.WardLocationSID
    AND Ward.Sta3n = '612'
  LEFT JOIN LSV.Dim.RoomBed AS Bed
    ON Inpatient.AdmitRoomBedSID = Bed.RoomBedSID
    AND Bed.Sta3n = '612'
WHERE
  SAddress.Sta3n = '612'
  AND SAddress.RelationshipToPatient = 'SELF'
  AND SAddress.AddressType = 'PATIENT'
  AND SPatient.TestPatientFlag IS NULL
  AND (
    HFT.HealthFactorType LIKE '%LOC%'
    OR HFT.HealthFactorType LIKE '%TYPE%'
	OR HFT.HealthFactorType LIKE '%NEW%'
	OR HFT.HealthFactorType LIKE '%STATUS%'
	OR HFT.HealthFactorType LIKE '%REMOVE%'
  )
  AND HFT.HealthFactorCategory LIKE 'CENTRAL%'
  AND DimCollectionSample.CollectionSample LIKE '%BLD%'
  AND HF.HealthFactorDateTime >= DATEADD(MONTH, -2, GETDATE())
  AND (
    HF.HealthFactorDateTime >= Inpatient.AdmitDateTime
	OR Inpatient.AdmitDateTime IS NULL
  )
  AND Microbiology.SpecimenTakenDateTime >= HF.HealthFactorDateTime
  AND (
    Inpatient.AdmitDateTime >= DATEADD(MONTH, -2, GETDATE())
	OR Inpatient.AdmitDateTime IS NULL
  )
  AND Microbiology.SpecimenTakenDateTime >= HF.HealthFactorDateTime
GROUP BY
  SPatient.PatientSID
  ,SPatient.PatientSSN
  ,SPatient.Sta3n
  ,SPatient.PatientName
  ,SPatient.Age
  ,SPatient.Gender
  ,MicroBiology.SpecimenTakenDateTime
  ,MicroBiology.RequestingWard
  ,MicroBiology.SpecimenComment
  ,DimCollectionSample.CollectionSample
  ,AntiSens.OrganismQuantity
  ,AntiSens.AntibioticSensitivityValue
  ,AntiSensComm.AntibioticSensitivityComments
  ,DimAntibiotic.Antibiotic
  ,DimAntibiotic.DrugNodeIEN
  ,DimAntibiotic.AntibioticDisplayComment
  ,DimAntibiotic.LabProcedure
  ,DimOrganism.Organism
  ,DimOrganism.OrganismCategory
  ,DimOrganism.GramStain
  ,SAddress.City
  ,SAddress.County
  ,SAddress.State
  ,SAddress.Zip
  ,SAddress.Zip4
  ,SAddress.GISPatientAddressLongitude
  ,SAddress.GISPatientAddressLatitude
  ,SAddress.GISFIPSCode
  ,SAddress.GISMarket
  ,SAddress.GISSubmarket
  ,Inpatient.AdmitDateTime
  ,HF.HealthFactorDateTime
  ,Inpatient.DischargeDateTime
  ,Ward.WardLocationName
  ,Bed.RoomBed
  ,HFT.HealthFactorType

ORDER BY
  SPatient.PatientName
  ,Inpatient.AdmitDateTime
  ,HF.HealthFactorDateTime
  ,Inpatient.DischargeDateTime
  ,MicroBiology.SpecimenTakenDateTime