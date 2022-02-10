/**
* Name: FRBModel
* Based on the internal empty template. 
* Author: desou
* Tags: 
*/


model FRBModel

species Field {
	
}

species LandOwner{
	
}

global {
	//geometry shape <- shape_file("../includes/Bacia_Formoso.shp") as geometry; //delimitating simulation area
	init{
		create Field from: shape_file("../includes/PropRurais_15km.shp");
	}
}


/* Insert your model definition here */

