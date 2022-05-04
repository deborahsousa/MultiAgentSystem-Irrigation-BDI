/**
* Name: FRBModel 
* Author: Deborah S. Sousa and Cássio G. Coelho
* Tags: irrigation; water regulation
*/

model FRB_Model

global {
	
	//Input data: shapefiles and matrices
	file shapefile_pumps <- file("../includes/bombas_gan2022.shp"); //irrigation pumps from GAN
	file shapefile_channels <- file("../includes/canais_semarh_clip.shp"); //irrigation channels from SEMARH
	file shapefile_land <- file("../includes/duxav.shp");
	matrix monthly_prices <- csv_file("../includes/MonthlyPrices.csv") as matrix; //sell prices for 60kg from CONAB
	matrix farmers_data <- csv_file("../includes/InputFarmerBehavior.csv") as matrix; //Farmer agents information
	float sb_s_productivity <- 1.10; //Soybean seed productivity of Tocantins seed [kg/ha]
		
	init {
		create Pump from: shapefile_pumps;
		
		create Farmer from: shapefile_land;
		
		/*number:52{
			location <- any_location_in(one_of(field));
			rgb color <- #black;
		}*/
	}
}

species FictionalReservoir {
	float init_water_level;
	float surface_area;
	float final_water_level;
	float current_level;
	float current_volume;
	
	reflex update_reservoir{
		if cycle = 0 {
			current_level <- init_water_level;
			current_volume <- init_water_level*surface_area;
		}else{
			current_level <- current_level - consumed_level;
			consumed_vol <- consumed_level*surface_area;
			current_volume <- current_volume - consumed_vol;
		}
	}
}

species Pump {	
	rgb color <- #grey;
}

species Regulator control: simple_bdi {
	float fiscalization_day <- 92; //End of July //Might be a simulation parameter
	matrix<float> PB_levels; //a 5 x 2 matrix (rivers x levels)
	float yld; //yellow level decrease [decimal] 0.0-0.99
	
	plan IssueRules intention: regulate_use{
		if current_level <= yellow_level{
			do add_belief(attention_rule);
			
		}else if current_level = red_level{			
			do add_belief(restriction_rule);
		} 
		//do add_belief(use_is_regulated,true);
		//do remove_intention(regulate_use, true);
	}
	
	rule belief: attention_rule new_desire: decrease_water_permit;
	rule belief: restriction_rule new_desire: suspend_water_withdraw;
	
	plan DecreasePermit intention: decrease_water_permit{
		float water_permit <- yld*water_permit; //decrease water permit
		do remove_intention(decrease_water_permit, true);
	}
	
	plan SuspendWithdraw intention: suspend_water_withdraw{
		float water_permit <- 0.0*water_permit; //suspend withdraw
		do remove_intention(suspend_water_withdraw, true);
	}
	
	plan IdentifyDisobFarmers intention: fiscalize_farmers{
		//list disob_farmers;
		//loop farmers over Farmers;
			//if farmers.tot_consume > farmers.permit{
				//add farmers to disob_farmers;
		do remove_intention(fiscalize_farmers, true);
	}
	
	plan ApplyPenalties intention: penalize_farmers{
		predicate apply_penalty <- new_predicate("apply penalty");
		// loop farmers over Farmers
			//if farmers in disob_farmers
				//farmers.permit <- 0.5*permit
	}

}

species Farmer control: simple_bdi {
	float compliance_level;
	
	plan IrrigateCrops intention: irrigate{
		float consumed_volume;
		string crop_stage;
		float compliance_level;
		consumed_volume <- compliance_level*water_permit;
	}

	
	rule belief:end_irrigation_period new_desire: sell_crops;
	plan SellCrops  intention: generate_income{
		//float production <- acc_consumed_volume*sb_s_productivity //[L*kg/ha]
		//float income <- production*irrigation_area*unit_sell_price //[kg*ha*R$/kg]
	}
	
	species CP_Farmer parent: Farmer{
		
	}
	
	species CI_Farmer parent: Farmer{
		
	}
	
	species NC_Farmer parent: Farmer{

	}
	
}	
 

/*experiment RegulatorProfiles type: gui{
	parameter: RegulatorProfile //inactive,active,proactive
	//individual income
	//colective income
	//total withdrawn water
	//total water level subtraction
	
}*/

/*experiment FarmerProfiles type: gui{
	parameter: profiledistribution //80/20,20/80,50/50
	//individual income
	//colective income
	//total withdrawn water
	//total water level subtraction
	 
}*/