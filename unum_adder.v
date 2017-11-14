//32-bit adder Universal number(unum)-Type III with 3-bit exponent bit in pipeline structure
//Dased on the document in http://superfri.org/superfri/article/view/137/232
//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
//Designed by Jianyu CHEN, in Delft, the Netherlands, in 29th Oct, 2017
//Email of designer: chenjy0046@gmail.com


module unum_adder(
	input clk,
	input[31:0] unum1,
	input[31:0] unum2,
	
	output[31:0] unum_o
);

//reg[31:0] unum1,unum2;
//always@(posedge clk)begin  ////////0th
//	unum1<=unum1_in;
//	unum2<=unum2_in;
//end
//1st: check whether the input number is special situations: zero and Inf
//If the number is nagative, change it from 2's complement to origital  
reg[1:0] isZero_1;   //isZero[1]: unum1   [0]: unum2    =0 if value is zero
reg[1:0] isInf_1;	 //isInf[1]: unum1    [0]: unum2    =1 if value is Inf
reg[31:0] temp1,temp2;  //store changed or unchange input numbers
reg[4:0] unum1_shift,unum2_shift; //result of zero/one counting
wire[4:0] n1,n2;//result of leading zero count
wire[30:0] unum1_2s,unum2_2s;
assign unum1_2s=~unum1[30:0]+31'b1;
assign unum2_2s=~unum2[30:0]+31'b1;
always@(posedge clk)begin  ////////1st
	if(unum1[30:0]==31'b0)begin isZero_1[1]<=unum1[31]; isInf_1[1]<=unum1[31]; end
	else begin isZero_1[1]<=1'b1; isInf_1[1]<=1'b0;end 
	
	if(unum2[30:0]==31'b0)begin isZero_1[0]<=unum2[31]; isInf_1[0]<=unum2[31]; end
	else begin isZero_1[0]<=1'b1; isInf_1[0]<=1'b0; end
	
	if(unum1[31])begin temp1<=unum1_2s; end  /// change unum from 2nd complement to original
	else begin temp1<=unum1[31:0]; end
	if(unum2[31])begin temp2<=unum2_2s; end
	else begin temp2<=unum2[31:0]; end
	
	unum1_shift<=n1;
	unum2_shift<=n2;
	
	temp1[31]<=unum1[31];
	temp2[31]<=unum2[31];
end
LZC lzc1(.x1(unum1[31]?unum1_2s:unum1[31:0]),.n(n1));
LZC lzc2(.x1(unum2[31]?unum2_2s:unum2[31:0]),.n(n2));
///2nd: seperate regime bits, exponent bits, sign bit and fraction bits
//change regime bits and exponent bits into exponent value in 2's complement format
//compare the absolut value of input numbers
reg isInf_2;  //if one of the input numbers is Inf, this bit will be 1
//reg[55:27] frac_num1_2,frac_num2_2; //[55]:sign bit    [54]:for carry on    [53]:1.   [52:27]fraction bits   [26:0] for shifting
reg[8:0] expo_num1, expo_num2; //store exponent values
reg[31:0] temp1_2,temp2_2;  //store changed or unchange input numbers
reg[1:0] isZero_2;   //isZero[1]: unum1   [0]: unum2    =0 if value is zero
reg compare_abs_2;             //equal to 1 if abs(unum1)>abs(unum2)
always@(posedge clk)begin        ///2nd
	temp1_2[30:0]<=temp1[30:0]<<unum1_shift;
	temp2_2[30:0]<=temp2[30:0]<<unum2_shift;
	temp1_2[31]<=temp1[31];
	temp2_2[31]<=temp2[31];
	if(temp1[30]) begin  expo_num1[7:3]<=unum1_shift; end
	else begin  expo_num1[7:3]<=~unum1_shift; end
	expo_num1[8]<=~temp1[30];
	
	
	if(temp2[30]) begin expo_num2[7:3]<=unum2_shift; end
	else begin expo_num2[7:3]<=~unum2_shift; end
	expo_num2[8]<=~temp2[30];
	
	isInf_2<=isInf_1[1]|isInf_1[0];
	compare_abs_2<=(temp1[30:0]>temp2[30:0]);
	isZero_2<=isZero_1;
end


//caculate the result of difference of two difference exponent value
reg[55:27] frac_num1_3,frac_num2_3; //[55]:sign bit    [54]:for carry on    [53]:1.   [52:27]fraction bits   [26:0] for shifting
reg[8:0] expo_numo_3;
reg compare_abs_3;
reg[8:0] diff_expo;//difference of two exponent values, [8] will always be zero because the difference is >=0
reg isInf_3;
always@(posedge clk)begin         //3rd
	frac_num1_3[55]<=temp1_2[31];
	frac_num2_3[55]<=temp2_2[31];
	
	frac_num1_3[53]<=isZero_2[1];
	frac_num2_3[53]<=isZero_2[0];
	
	frac_num1_3[52:27]<=temp1_2[25:0];
	frac_num2_3[52:27]<=temp2_2[25:0];
	compare_abs_3<=compare_abs_2;
	
	if(compare_abs_2)begin expo_numo_3<={expo_num1[8:3],temp1_2[28:26]}; diff_expo<={expo_num1[8:3],temp1_2[28:26]}-{expo_num2[8:3],temp2_2[28:26]}; end
	else begin expo_numo_3<={expo_num2[8:3],temp2_2[28:26]};	diff_expo<={expo_num2[8:3],temp2_2[28:26]}-{expo_num1[8:3],temp1_2[28:26]};end
	
	compare_abs_3<=compare_abs_2;
	isInf_3<=isInf_2;
end


//4th: shift fraction bits
reg[55:0] frac_num1_4,frac_num2_4;
reg[8:0] expo_numo_4;
reg isInf_4;
reg compare_abs_4;
always@(posedge clk)begin			///4th
	if(compare_abs_3)begin
		frac_num2_4[53:0]<={frac_num2_3[53:27],27'b0}>>diff_expo[7:0];
		frac_num1_4[53:0]<={frac_num1_3[53:27],27'b0};
	end
	else begin
		frac_num1_4[53:0]<={frac_num1_3[53:27],27'b0}>>diff_expo[7:0];
		frac_num2_4[53:0]<={frac_num2_3[53:27],27'b0};
	end
	
	expo_numo_4<=expo_numo_3;
	isInf_4<=isInf_3;
	frac_num2_4[55:54]<={frac_num2_3[55],1'b0};
	frac_num1_4[55:54]<={frac_num1_3[55],1'b0};
	compare_abs_4<=compare_abs_3;
end


//5th: add fraction(in signed magnitude format) of unum1 and unum2 
reg[55:0] frac_numo_5;  //result of addition [55]:sign  [54]:carry  [53]: 1.   [52:27]: fraction  [26]: rounding
reg[8:0] expo_numo_5;
reg isInf_5;
wire[54:0] frac_add;

always@(posedge clk)begin  //5th
	if(frac_num1_4[55]==frac_num2_4[55]) begin frac_numo_5[55]<=frac_num1_4[55]; frac_numo_5[54:26]<=frac_num1_4[53:26]+frac_num2_4[53:26]; end
	else if(compare_abs_4) begin frac_numo_5[55]<=frac_num1_4[55]; frac_numo_5[54:26]<=frac_num1_4[53:26]-frac_num2_4[53:26]; end
	else begin frac_numo_5[55]<=frac_num2_4[55]; frac_numo_5[54:25]<=frac_num2_4[53:26]-frac_num1_4[53:26]; end
	isInf_5<=isInf_4;
	expo_numo_5<=expo_numo_4;
end


//6th: shift frac_numo to do the normalization
reg[55:0] frac_numo_6;
reg[8:0] expo_numo_6;
reg isZero_6;
reg isInf_6;
wire[4:0] frac_shift;
always@(posedge clk)begin    //6th
	frac_numo_6[53:25]<=frac_numo_5[54:26]<<frac_shift;
	expo_numo_6<=expo_numo_5+9'd1-{4'b0,frac_shift};
	isZero_6<=(frac_shift!=5'd29);

	isInf_6<=isInf_5;
	frac_numo_6[55]<=frac_numo_5[55];	
end
LZC_fraction lzc_fraction(.x({frac_numo_5[54:26],3'b100}),.n(frac_shift)	);


//7th: change fraction and exponent value to unum format
//do the rounding following the recommended way
reg[31:0] runum_o_7;
wire signed[31:0] shift;
assign shift={~expo_numo_6[8]&isZero_6,expo_numo_6[8]&isZero_6,expo_numo_6[2:0]&{isZero_6,isZero_6,isZero_6},frac_numo_6[52:26]};
reg round;  // 1: the final result should add 1 
reg isInf_7;
always@(posedge clk)begin//7th
		{runum_o_7[30:0],round}<=shift>>>(expo_numo_6[8]?(~expo_numo_6[7:3]):expo_numo_6[7:3]);

		runum_o_7[31]<=frac_numo_6[55]&isZero_6;
		isInf_7<=isInf_6;	
end

//8th: if the result is negative, change [30:0] to 2's implement
//add round
reg[31:0] runum_o_8;
always@(posedge clk)begin//8th
	if(isInf_7) begin runum_o_8[31:0]<=32'h8000_0000; end
	else if(runum_o_7[31])begin runum_o_8[30:0]<=~runum_o_7[30:0]+32'd1+{31'd0,round}; runum_o_8[31]<=runum_o_7[31]; end
	else begin runum_o_8[30:0]<=runum_o_7[30:0]+{31'd0,round};	runum_o_8[31]<=runum_o_7[31];end
end


assign unum_o=runum_o_8;

endmodule

//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
module LZC(
			input[30:0] x1,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg[31:0] x;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	if(x1[30]) begin x[31:2]=~x1[29:0]; end			//if the number starts with 1, inverse it
	else begin x[31:2]=x1[29:0]; end
	x[1:0]=2'b10;
	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule


module LZC_fraction(
			input[31:0] x,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule



module BNE(
			input[7:0] a,
			output[2:0] y 
			);
assign y[2]=a[0]&a[1]&a[2]&a[3];
assign y[1]=a[0]&a[1]&(~a[2]|~a[3]|(a[4]&a[5]));
assign y[0]=a[0]&(~a[1]|(a[2]&~a[3]))|(a[0]&a[2]&a[4]&(~a[5]|a[6]));
endmodule



module NLC(
			input[3:0] x,
			output a,
			output[1:0] z
			);

assign z[1]=~(x[3]|x[2]);
assign z[0]=~(((~x[2])&x[1])|x[3]);
assign a=~(x[0]|x[1]|x[2]|x[3]);
endmodule 