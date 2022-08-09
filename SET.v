module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

reg [3:0] curt_state;
reg [3:0] next_state;

reg [3:0] Px,Py;
reg [3:0] R;

reg [4:0] pos_x;
reg [4:0] pos_y;



reg [7:0] Da,Db,Dr;
reg [2:0] Circle;
// 0 = A, 1 = B, 2 = C
reg In, In_a, In_b, In_c;
always @(*) 
begin
    if( Da + Db > Dr )
        In = 0;
    else
        In = 1;
end

//C Circuit
always @( * ) // State Control ( next state condition )
begin 
    
    case ( curt_state )
        0 :
        begin
            next_state = 1;
        end  
        1 :
        begin
            next_state = 2;
        end
        2 :begin
            next_state = 3;                          
        end
        3 :begin
            next_state = 4;
        end
        4 :begin
            next_state = 5;
        end
        5 :begin
            next_state = 6;
        end
        6 :begin
            if( mode == 1 && Circle == 0 )
                next_state = 15;
            else if( mode == 2 && Circle == 0 )
                next_state = 15;
            else if( mode == 3 && Circle == 0 )
                next_state = 15;
            else if( mode == 3 && Circle == 1 )
                next_state = 14;
            else
                next_state = 7;                
        end
        7 :begin
            if( pos_x == 8 && pos_y == 8 )
                next_state = 8;
            else
                next_state = 1;
        end
        8 :begin
            next_state = 0;
        end
        //Circle A 做完
        9 :begin
            next_state = 2;
        end
        10 :begin
            next_state = 10;                
        end
        //Circle B 給值
        15 :begin
            next_state = 2;
        end
        //Circle C 給值
        14 :begin
            next_state = 2;
        end
        default: 
            next_state = 0;
    endcase
    
end


wire [7:0] product;
reg [3:0] multiplier;
assign product = multiplier * multiplier;



//S Circuit
always @( posedge clk or posedge rst) begin
    if( rst )
    begin
        busy <= 0;
        valid <= 0;
        // candidate <= 0;
        // pos_x <= 0;
        // pos_y <= 0;
        // Da <= 0;
        // Db <= 0;
        // Dr <= 0;
        // Circle <= 0;
        // multiplier <= 0;
        // In_a <= 0;
        // In_b <= 0;
        // In_c <= 0;
        // Px <= 0;
        // Py <= 0;
        // R <= 0;
        curt_state <= 0;
    end
    else
    begin
        curt_state <= next_state;
        case ( curt_state )
            0 : begin   
                valid <= 0;
                busy <= 0;          
                pos_x <= 1;
                pos_y <= 1; 
                candidate <= 0;  
            end
            //
            1 :
            begin   
                valid <= 0;
                busy <= 0;
                //Circle A 
                Circle <= 0;            
                Px <= central[23:20];
                Py <= central[19:16];
                R  <= radius[11:8];
                In_a <= 0;
                In_b <= 0;
                In_c <= 0;
            end
            //Circle B   
            15 :
            begin  
                //Circle B
                Circle <= 1;       
                Px <= central[15:12];
                Py <= central[11:8];
                R  <= radius[7:4];                 
            end
            //Circle C  
            14 :
            begin  
                //Circle C
                Circle <= 2;       
                Px <= central[7:4];
                Py <= central[3:0];
                R  <= radius[3:0];                  
            end
            //
            2 :
            begin     
                if( Px >= pos_x )   
                    multiplier <= Px - pos_x;
                else
                    multiplier <= pos_x - Px; 
            end
            //乘積完的結果            
            3 :
            begin  
                Da <= product;
                if( Py >= pos_y )   
                    multiplier <= Py - pos_y;
                else
                    multiplier <= pos_y - Py;
            end  
            //可以不用每次做          
            4 :
            begin  
                Db <= product;
                multiplier <= R;          
            end                            
            5 :
            begin
                Dr <= product; 
            end           
            6 :
            begin
                if( Circle == 0 )
                //Circle A 是否 In
                begin                    
                    In_a <= In; 
                end  
                else if( Circle == 1 )                               
                //Circle B 是否 In
                begin
                    In_b <= In; 
                end
                else                               
                //Circle C 是否 In
                begin
                    In_c <= In; 
                end                   
            end
            //移動下個點
            7 :
            begin
                if( ( mode == 2 && In_a == 0 && In_b == 1) || ( mode == 2 && In_a == 1 && In_b == 0) )
                begin
                    candidate <= candidate + 1;
                end
                if( ( mode == 3 && In_a == 1 && In_b == 1 && In_c == 0) || ( mode == 3 && In_a == 1 && In_b == 0 && In_c == 1) || ( mode == 3 && In_a == 0 && In_b == 1 && In_c == 1) )
                begin
                    candidate <= candidate + 1;
                end
                //mode 0 || mode 1
                if( In )
                begin
                    if( mode == 1 && In_a == 1 && In_b == 1 )
                    begin
                        candidate <= candidate + 1;
                    end
                    
                    if( mode == 0 )
                        candidate <= candidate + 1;
                end             
                if( pos_x < 8 )
                begin                    
                    pos_x <= pos_x + 1;
                end
                else
                begin
                    pos_x <= 1;
                    pos_y <= pos_y + 1;
                end  
                In_a <= 0;
                In_b <= 0;  
                Circle <= 0;          
            end
            8 :
            begin
                valid <= 1;
                busy <= 1;
            end
            9 :
            begin
                valid <= 0;
                busy <= 0;
            end
            // 10 :
            // begin
                
            // end
            // default: 
            // begin
                
            // end
        endcase

    end
end

endmodule


