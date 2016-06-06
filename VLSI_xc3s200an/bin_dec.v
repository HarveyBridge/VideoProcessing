`timescale 1ns / 1ps

module bin_dec(clk,Input,rst_n,one,ten,hun);
input  [7:0] Input;
input        clk,rst_n;
output [3:0] one,ten;
output [1:0] hun;

reg    [3:0] one,ten;
reg    [1:0] hun;
reg    [3:0] count;
reg    [17:0]shift_reg=18'b000000000000000000;

always @ ( posedge clk or negedge rst_n )
begin
	if( !rst_n )
		count<=0;
	else if (count==9)
		count<=0;
	else
		count<=count+1;
end

always @ (posedge clk or negedge rst_n )
begin
	if (!rst_n)
		shift_reg=0;
	else if (count==0)
		shift_reg={10'b0000000000,Input};
	else if ( count<=8)               
	begin
		if(shift_reg[11:8]>=5)         
        begin
            if(shift_reg[15:12]>=5) 
            begin
				shift_reg[15:12]=shift_reg[15:12]+2'b11;   
				shift_reg[11:8]=shift_reg[11:8]+2'b11;
				shift_reg=shift_reg<<1;  
			end
            else
			begin
                shift_reg[15:12]=shift_reg[15:12];
				shift_reg[11:8]=shift_reg[11:8]+2'b11;
				shift_reg=shift_reg<<1;
			end
          end              
		else
        begin
            if(shift_reg[15:12]>=5)
            begin
				shift_reg[15:12]=shift_reg[15:12]+2'b11;
				shift_reg[11:8]=shift_reg[11:8];
				shift_reg=shift_reg<<1;
			end
            else
			begin
                shift_reg[15:12]=shift_reg[15:12];
				shift_reg[11:8]=shift_reg[11:8];
				shift_reg=shift_reg<<1;
			end
        end        
	end
end


always @ ( posedge clk or negedge rst_n )
begin
	if ( !rst_n )
	begin
		one<=0;
		ten<=0;
		hun<=0; 
	end
	else if (count==9)  
	begin
		one<=shift_reg[11:8];
		ten<=shift_reg[15:12];
		hun<=shift_reg[17:16]; 
	end
end
endmodule