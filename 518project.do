*install asdoc program
ssc install asdoc
sysuse framingham_2021

*label variables
label variable sex "Participant Sex"
label variable totchol "Total Cholesterol (mg/dL)"
label variable educ "Education"
label variable bmi "Body Mass Index (kg/m2)"
label variable age "Age at Baseline Examination"
label variable sysbp "Systolic Blood Pressure (mmHg)"
label variable cursmoke "Current Cigarette Smoker"
label variable diabetes "Diabetes"

label define sex_ 1 "Male"  2 "Female"
label values sex sex_

label define educ_ 1 "0-11 years" 2 "High School" 3"Some college" 4 "College degree"
label values educ educ_

label define cursmoke_ 0 "No" 1 "Yes"
label values cursmoke cursmoke_

label define diabetes_ 0 "No" 1 "Yes"
label values diabetes diabetes_

*1a. summary statistics
*cont var
asdoc sum totchol bmi age sysbp, detail title(Descriptive Statistics for Independent Variables) fhc(\b)label by(mi_chd) replace

*cat var
bys mi_chd: asdoc tab1 sex educ cursmoke diabetes, fhc(\b) label

*2a. kaplan-meier curve
stset lasttime, failure(mi_chd==1)
sts graph, by(diabetes)

*2b. estimates of cum survival
sts list,by (diabetes)

*2c. test for diff in survival
sts test diabetes

*3a.i. martingale residuals
stcox, estimate
predict mg, mgale
lowess mg sysbp
lowess mg totchol
lowess mg bmi

*3a.iii. center variables
summarize sysbp, meanonly
gen c_sysbp = sysbp - r(mean)
summarize totchol, meanonly
gen c_totchol = totchol - r(mean)
summarize bmi, meanonly
gen c_bmi = bmi - r(mean)

*3b. univariate associations
stcox c_sysbp
stcox c_totchol
stcox c_bmi
stcox i.cursmoke
stcox i.diabetes
stcox age
stcox i.sex
stcox i.educ

*3c.i. base model
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes, nohr
estat ic

*3c.ii. test for confounder
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, nohr
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes i.sex, nohr
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes i.educ, nohr

*new model:
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age i.sex
estat ic

*3d. test for proportional hazards assumption
*method 1. schoenfeld residual
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age i.sex, scaledsch(sca*) schoenfeld(sch*)
estat phtest, detail
estat phtest, plot(2.sex)

*method 2. interaction with analysis time 
stcox c_sysbp c_totchol c_bmi cursmoke diabetes age i.sex, tvc (c_sysbp c_totchol c_bmi cursmoke diabetes age i.sex) texp (ln(_t))

*method 3. graphing
stphplot, by (sex) 
stcoxkm, by(sex)

*stratified analysis
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, strata(sex)
estat ic

*model diagnostics
*3e.i. cox-snell residuals
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, strata(sex)
predict csr, csnell
stset csr, fail(mi_chd==1)
sts gen cumhaz = na
line cumhaz csr csr, sort

*3e.ii. influential observations
stset lasttime, failure(mi_chd==1)
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, strata(sex)
predict dbsbp dbchol dbbmi dbsmk dbdia dbage dbmale dbfemale, dfbeta
sum dbsbp dbchol dbbmi dbsmk dbdia dbage dbmale dbfemale
scatter dbsbp _t, yline(0)
scatter dbchol _t, yline(0)
scatter dbbmi _t, yline(0)
scatter dbsmk _t, yline(0)
scatter dbdia _t, yline(0)
scatter dbage _t, yline(0)
scatter dbmale _t, yline(0)
scatter dbfemale _t, yline(0)

*3e.iii. likelihood displacement
predict ldisp, ldisplace
sum ldisp
scatter ldisp _t, yline(0) mlabel(randid)

*3f. publication quality table
asdoc stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, strata(sex)
asdoc stcox c_sysbp, strata(sex)
asdoc stcox c_totchol, strata(sex)
asdoc stcox c_bmi, strata(sex)
asdoc stcox i.cursmoke, strata(sex)
asdoc stcox i.diabetes, strata(sex)
asdoc stcox age, strata(sex)

*4. liklihood ratio test
stset lasttime, failure(mi_chd==1)
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age, strata(sex)
est store model
stcox c_sysbp c_totchol c_bmi i.cursmoke i.diabetes age i.diabetes#c.c_totchol, strata(sex)
lrtest model


