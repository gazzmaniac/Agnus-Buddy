module ECS_ChipRamSwitcher(
// Clocks
		input		CCK,
		input		CCKQ,
		input		CCKD,
		input		CCKQD,

// Address Bus
		input		[1:8] RGA,

// DRD Data Bus								//I'd have liked to have it as a 16 bit IO register but we're constrained by the CPLD size
		output	[0:7] DRDO,					//input for the status register
		input		[8:15] DRDI,				//output for the control register

// Reset and bank config lines 
		input		_RST,
//		input		[0:3] NUMBANKS,		//these are for status register
//		input		SIZE,

// Bank Selection Lines
		output [0:15] BANKSEL,

// Some LEDs for debugging
		output	LED0,
		output	LED1,
		output	LED2,	
		output	LED3
);

// some constants
parameter addBANKC = 8'b000011111;		// address for BANKC register.  b111110000 is h1F0 but the bits are backwards for big endian shit
parameter addCONFIG = 8'b001011111;		// address for CONFIG register.  b111110100 is h1F4 but the bits are backwards
parameter addSTATUS = 8'b011011111;		// address for STATUS register.  b111110010 is h1F6 but the bits are backwards

// configuration constant
// there is circuitry on the card to do this with jumpers but I can't be fucked
// Bits 7-3 are the number of banks minus one (i.e. 0 to 15), in binary.  It's in reverse (i.e. least significant bit is bit 7)  
// Bits 1&2 are not in use so should be set to 0.  Bit 0 is 1 if the bank size is 1 MB and 0 if it is 512 kB, this is for a future version for 1 MB agnus
// Bit number:               76543210
parameter configuration = 8'b10000001;

// set up the clocks
//wire _CCK;						//will just use the negative edge of CCK, due to space on CPLD
wire PHI2;							
wire PHI1;

assign PHI1 = CCKD & ~CCKQ;   
//assign _CCK = ~CCK;
assign PHI2 = CCKQD | ~CCK;   

// internal latched buses
reg [0:8] LRGA=0;						// Latched RGA bus (address bus)
reg [0:15] LDRDI=0;					// Latched DRD bus (data bus) 
reg [0:7] LRDO=8'bz;					// Latched output register

reg [0:15] BCR=0;						//BCR latches are the bank control register, this is the input register that controls what the card is doing 
reg [0:15] BANKNUM=16'hFFFF;		//This register controls the output lines BANKSEL


reg STATUS=0;												// these are internal control lines, and also control the LEDs 0-3
reg CONFIG=0;
reg WRITE=0;												// this line was used during development to operate LED0
reg DSBNK=1;
reg CNBNK=0;
reg RPBNK=0;

// The bank select outputs
assign BANKSEL = BANKNUM;

// The DRD Bus output assign
assign DRDO=LRDO;

// LED Outputs
assign LED0 = _RST;
assign LED1 = DSBNK;
assign LED2 = CNBNK;
assign LED3 = RPBNK;



// sample the DRD bus
always @(negedge CCK) begin
	if(_RST) begin 											//latch the DRD bus onto the LDRDI register on clock _CCK if the reset line is not asserted (it is active low) 
		LDRDI[8:15]=DRDI[8:15];												
	end else begin												//on reset the DRD bus is ignored, and the LDRDI latches set to 0
		LDRDI[8:15]=0;
	end		
end


// RGA Latches

always @(posedge PHI1) begin
	if(_RST) begin 											//latch the RGA bus onto the LRGA register on clock PHI if the reset line is not asserted (it is active low) 
		LRGA[1:8] = RGA[1:8];						
	end else begin												//on reset the bus is ignored, and LRGA register is made to equal the addBANKC unless RPBNK is asserted
		if (RPBNK==0) begin									//this effectively issues the DSBNK instruction if RPBNK is not asserted
			LRGA=addBANKC;
		end else begin
			LRGA=0;
		end
	end	
end

// Address decoding
always @(LRGA) begin											//whenever there is a new address in LRGA
	if(LRGA==addBANKC) begin
		BCR[8:15]= LDRDI[8:15];								//if it's addBANKC then we sample the data bus into BCR
		BANKNUM[8:15]=LDRDI[8:15];							//also make a copy of this byte onto BANKNUM register so we can see what is going on.  Delete this when we need banks 8-15
	end 
	
	//STATUS and CONFIG are read only registers so strobing the address is all that is required to trigger an output output
	if(LRGA==addSTATUS) begin								
		STATUS=1;												//if it's the address is addSTATUS then assert signal STATUS
	end else begin												//STATUS needs to be unasserted when the RGA bus changes
		STATUS=0;
	end
	
	if(LRGA==addCONFIG) begin
		CONFIG=1;												//if it's the address is addCONFIG then assert signal CONFIG
	end else begin												//CONFIG needs to be unasserted when the RGA bus changes
		CONFIG=0;
	end
	
end


//  Determining the instruction for the bank control register
always @(BCR) begin								//when we have a new instruction - the bytes are backwards of course, thanks motorola!
	case(BCR[12:15])
		4'b0000	:	begin							//if it's instruction 0 DSBNK is asserted
							DSBNK=1;
							CNBNK=0;
							RPBNK=0;
						end

		4'b0100	:	begin							//if it's instruction 2 CNBNK is asserted
							DSBNK=0;
							CNBNK=1;
							RPBNK=0;
						end	
			
		4'b0110	:	begin							//if it's instruction 6 RPBNK is asserted
							DSBNK=0;
							CNBNK=0;
							RPBNK=1;
						end			
		default	:	begin							//default is an illegal instruction and it's the same as instruction 0
							DSBNK=1;
							CNBNK=0;
							RPBNK=0;
						end			

	endcase
end

// Instructions for the bank control register
always @(DSBNK or CNBNK or RPBNK) begin	
	if(DSBNK) begin								//if it's DSBNK disconnect all the banks
		BANKNUM[0:7]=8'bzzzzzzzz;
	end else if(CNBNK | RPBNK) begin			//if it's RPBNK or CNBNK connect the bank number specified in the second half of the instruction
		case(BCR[8:11])
			/*			
			4'b0000	:	BANKNUM[0:7]=8'b10000000;
			4'b1000	:	BANKNUM[0:7]=8'b01000000;
			4'b0100	:	BANKNUM[0:7]=8'b00100000;
			4'b1100	:	BANKNUM[0:7]=8'b00010000;
			4'b0010	:	BANKNUM[0:7]=8'b00001000;
			4'b1010	:	BANKNUM[0:7]=8'b00000100;
			4'b0110	:	BANKNUM[0:7]=8'b00000010;
			4'b1110	:	BANKNUM[0:7]=8'b00000001;
			default	: 	BANKNUM[0:7]=8'b00000000;
			*/
			
			4'b0000	:	BANKNUM[0:7]=8'b01111111;
			4'b1000	:	BANKNUM[0:7]=8'b10111111;
			4'b0100	:	BANKNUM[0:7]=8'b11011111;
			4'b1100	:	BANKNUM[0:7]=8'b11101111;
			4'b0010	:	BANKNUM[0:7]=8'b11110111;
			4'b1010	:	BANKNUM[0:7]=8'b11111011;
			4'b0110	:	BANKNUM[0:7]=8'b11111101;
			4'b1110	:	BANKNUM[0:7]=8'b11111110;
			default	: 	BANKNUM[0:7]=8'bzzzzzzzz;
			
			
		endcase
	end
end



// Instruction for the STATUS and CONFIG registers
always @(PHI2) begin							//this instruction is executed whenever the PHI2 bus is changed, i.e. on the positive and negative edges
	LRDO=8'bz;									//first always disconnect LRDO, this is the default situation
	WRITE=0;
	if(STATUS) begin							//if STATUS is asserted output the bank control register to the DRD bus
		LRDO=BCR[8:15];
		WRITE=1;
	end
	
	if(CONFIG) begin							//if CONFIG is asserted output the configuration value is put on the DRD bus
		LRDO=configuration;
		WRITE=1;
	end
end


endmodule

