#!/usr/bin/env python

import os
import glob 
import numpy as np

def find_refHead(raw_name='raw.fif',dossier=0):
# Fonction python servant a choisir le fichier blablabla.fif parmi tous ceux contenus dans le dossier qui donnera la position-reference de la tete. 
# Mettre d'abord en argument un string indiquant la nomenclature des fichiers qui doivent etre analyses (les fichiers raw en l'occurence) Par defaut, on considere qu'ils finissent en "raw.fif"
#  Mettre ensuite en argument le chemin (relatif ou absolu) du dossier. Par defaut, le dossier courant est selectionne.

	
	# On note le dossier de depart
	homeDir= os.getcwd()
	
	# Par defaut le dossier est le repertoire courant
	if dossier ==0:
		dossier= homeDir
		
	# On se place dans le dossier 
	os.chdir(dossier)
	
	# Creation d'une liste contenant le nom des fichiers raw.fif presents dans le repertoire courant
	fifFiles= glob.glob('*'+raw_name)
	Files_tot= len(fifFiles)

	try:
		# Array contenant les coordonnees de la tete de chaque fichier raw.fif
		AllCoords= np.zeros((Files_tot,3))
 
		#Pour chaque fichier raw.fif:
		for index, eachFile in enumerate(fifFiles):

			# On recupere les coordonnees de la tete
			coords= os.popen("show_fiff -vt 222 "+ eachFile + " | tail -n 1").read().replace(')',"").split()
			coords= coords[4:7]

			# On les place dans une matrice
			AllCoords[index,:]= np.array([float(s) for s in coords])

		# On evalue les coordonnees moyennes
		Average= np.mean(AllCoords, axis=0)

		# On evalue ensuite les distances a cette moyenne 
		Distances= np.sqrt(np.sum((AllCoords-Average)**2, axis=1))

		# On selectionne enfin le min et on voit a quel fichier il correspond
		TheFile= np.array(fifFiles)[Distances==np.min(Distances)]
		TheFile= TheFile[0]
		print TheFile
		return TheFile
	
	except ValueError:
		print "Je ne trouve aucun fichier", raw_name, "!!!"
	
	finally:
		os.chdir(homeDir)
	

# Pour pouvoir appeler la fonction depuis le bash:
#if __name__=='__main__':
	#import sys
	#try:
		#func= sys.argc[1]
	#except:
		#func= None
	#if func:
		#try:
			#exec 'print %s' % func
		#except:
			#print "Error: incorrect syntax '%s'" %func
			#exec 'print %s.__doc__' % func.split('(')[0]
		
	
