# Importing Abaqus
# Do not alter these lines

################### IMPORTS ################### 

from abaqus import *
# from sketch import *
# from part import *
# from material import *
# from section import *
# from assembly import *
# from load import *
from visualization import *
# from interaction import *
# from step import *
# from mesh import *
# from job import *
from odbAccess import *
# from shutil import *

# import section
# import regionToolset
# import displayGroupMdbToolset as dgm
# import part
# import material
# import assembly
# import step
# import interaction
# import load
# import mesh
# import job
# import sketch
import visualization
import xyPlot
import displayGroupOdbToolset as dgo
# import connectorBehavior
import odbAccess
import os

	
# Iteration number
print '\nReading iteration number...\n'
f=open('iteration.txt','r')
itnum=f.readlines()
f.close()
    
# open the output database
odb=session.openOdb('CorticalAndTrabecularIteration'+"%04d" % int(itnum[0])+'.odb', readOnly=True)

#extract the axial strain values for the trabecular elements
strains=odb.steps['Step-1'].frames[1].fieldOutputs['E']

####
# getting data for the Trabecular Bone
outputpointstrab=odb.rootAssembly.instances['STRUCTURALFEMUR-1'].elementSets['ES_TRABECULAR']
straintrab01 = strains.getSubset(region=outputpointstrab, position=INTEGRATION_POINT)
straintrabvalues = straintrab01.values

#open a file to put the data in
straintrabdata=open('strains_trab_bars_iteration'+"%04d" % int(itnum[0])+'.txt',"w")

print 'Writing Trabecular Strain Data...'

# write the date to the file
for v in straintrabvalues:
            straintrabdata.write('%d,' % (v.elementLabel))
            straintrabdata.write('%1.12e\n' % (v.data[0]))

# close the file   
straintrabdata.close()

print 'Done.'
####

####
# getting data for the Cortical Bone

outputpointscort=odb.rootAssembly.instances['STRUCTURALFEMUR-1'].elementSets['ES_CORTICAL']

# using different section points (SP1 - Bottom)

straincort01SP1 = strains.getSubset(region=outputpointscort, position=INTEGRATION_POINT, sectionPoint=strains.locations[0].sectionPoints[0])
straincortvaluesSP1 = straincort01SP1.values

#open a file to put the data in
straincortdataSP1=open('strains_cortSP1_bars_iteration'+"%04d" % int(itnum[0])+'.txt',"w")

print 'Writing Cortical Strain Data, SP1'

# write the date to the file
for v in straincortvaluesSP1:
            straincortdataSP1.write('%d,' % (v.elementLabel))
            straincortdataSP1.write('%1.12e,' % (v.minPrincipal))
	    straincortdataSP1.write('%1.12e\n' % (v.maxPrincipal))

# close the file   
straincortdataSP1.close()

# using different section points (SP2 - Top)

straincort01SP2 = strains.getSubset(region=outputpointscort, position=INTEGRATION_POINT, sectionPoint=strains.locations[0].sectionPoints[1])
straincortvaluesSP2 = straincort01SP2.values

#open a file to put the data in
straincortdataSP2=open('strains_cortSP2_bars_iteration'+"%04d" % int(itnum[0])+'.txt',"w")

print 'Writing Cortical Strain Data, SP2'

# write the date to the file
for v in straincortvaluesSP2:
            straincortdataSP2.write('%d,' % (v.elementLabel))
            straincortdataSP2.write('%1.12e,' % (v.minPrincipal))
	    straincortdataSP2.write('%1.12e\n' % (v.maxPrincipal))

# close the file   
straincortdataSP2.close()

print 'Done.'

#close the output database
odb.close()