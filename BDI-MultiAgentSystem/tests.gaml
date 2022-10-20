/**
* Name: tests
* Based on the internal empty template. 
* Author: desou
* Tags: 
*/


model tests

global {
	matrix<float> prob_CP <- file("../includes/CP-prob.csv");

	init {
		create Test;
	}
	
	reflex {
		save[cycle,int(self)] to:'teste.csv' type:csv rewrite:false;
	}
}

species Test {
	reflex test {
		list<float> p_list <- prob_CP column_at 0;
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

experiment teste_batch type:batch repeat:100 keep_seed: false until: cycle = 123 {
	
}


