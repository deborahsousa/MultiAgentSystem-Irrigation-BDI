/**
* Name: tests
* Based on the internal empty template. 
* Author: desou
* Tags: 
*/

model tests

global {
	list<string> daily_date <- file("../includes/daily_date.txt") as list<string>;
	date my_day <- daily_date[cycle];
	date day_of_the_year;
	float step <- 1 #day;
	date starting_date <- date("2020-05-01"); 
	date attention_date <- date("2020-07-01");
	date restriction_date <- date("2020-08-01");
	float initial_level <- 4.5; //fictional
	bool aux_date_08 <- (current_date >= restriction_date);
	bool aux_date_07 <- (current_date >= attention_date);
	bool my_eval1 <- day_of_the_year >= attention_date;
	//bool my_eval <-   > ;
	reflex {
		if cycle > 1{
			day_of_the_year <- daily_date[cycle-1];
		}
		write day_of_the_year;
		write my_eval1;
		//write cycle;
		/*write attention_date.day;
		write attention_date.month;*/
		//write day_of_the_year[5];
		//write current_date;
		/*write current_date;
		write '07:' +aux_date_07;
		write '08:' +aux_date_08;*/
	}
	
	matrix<float> prob_CP <- file("../includes/CP-prob.csv");

	init {
		create Test;
	}
	
	reflex {
		//save[cycle,int(self)] to:'teste.csv' type:csv rewrite:false;
	}
}

species Test {
	reflex test {
		/*list<float> p_list <- prob_CP column_at 0;
		list p_list <- p_list collect (each*0.1);
		list p_list1 <- [0.39,0.0001,0.2,0.2,0.2];
		int interval_index0 <- rnd_choice(p_list1);
		int interval_index1 <- rnd_choice([p_list[0],p_list[1],p_list[2],p_list[3],p_list[4]]);
		int interval_index2 <- rnd_choice(p_list[0],p_list[1],p_list[2],p_list[3],p_list[4],p_list[5],p_list[6],p_list[7],p_list[8],p_list[9],p_list[10],p_list[11],p_list[12],p_list[13],p_list[14],p_list[15],p_list[16],p_list[17],p_list[18],p_list[19],p_list[20],p_list[21]);
		/*write 'index0: '+ interval_index0;
		write 'index1: '+ interval_index1;
		write 'index2: '+ interval_index2;*/


	
	}
}

experiment teste_batch type:batch repeat:1 keep_seed: false until: cycle = 125 {
	
}


