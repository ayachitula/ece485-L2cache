/* This lays out the Finite State Machine (FSM) that will control most of the operations within the cache memory.
 *  It is primarily dependent on the MESI protocol and the need to maitain the inclusivity property.  It is based
 *  on the two example FSMs in the cache slides provided by Professor Mark Faust and the the FSM implemented
 *  by PowerPC to do the same.
 */

module cache_FSM(CLK, RST, COMMAND, FSB, L1BUS, HM, STATE);
  // Declare input/output types, sizes, and uses
  input         CLK;                      // Clock to run the FSM
  input [31:0]  COMMAND;                  // Command is an integer giving the current operation being pushed to L2
  inout [31:0]  L1BUS;                    // Bus between Data/Instruction Caches and L2 Cache
  inout [63:0]  FSB;                      // Shared bus between others processors and memory
  inout [1:0]   HM;                       // Takes the HIT/HITM/MISS signals from FSB: 0 MISS, 1 HIT, 2 HITM
  inout [3:0]   STATE;                    // The current state of the working address

  // Establish needed variables and parameters
  reg           next_state;               // Used for state transitioning
  localparam    MODIFIED    = 4'b0001;    // Params used for MESI protocol
  localparam    EXCLUSIVE   = 4'b0010;
  localparam    SHARED      = 4'b0100;
  localparam    INVALID     = 4'b1000;


  /**********************************************************************************************************/
  /*  The following is the finite state machine that will perform the appropriate operations for the MESI   */
  /*   protocol.  It will take into account the current state and any other necessary input to determine    */
  /*   the next state.                                                                                      */
  /**********************************************************************************************************/

  // Performs state transition
  always @(posedge CLK or negedge RST)
  begin
    if(!RST)
      // Call clear and reset function
    else
      STATE = next_state;
  end

  // Gives next state
  always @(*)
  begin
    case(current_state)
      MODIFIED:   if      (COMMAND == 0)  begin PASS2L1('L1DR'); next_state = MODIFIED; end
                  else if (COMMAND == 1)  begin WRITE2L2; next_state = MODIFIED; end
                  else if (COMMAND == 2)  next_state = MODIFIED;  // not sure because should not happen?
                  else if (COMMAND == 3)  next_state = MODIFIED;  // not sure because should not happen?
                  else if (COMMAND == 4)  next_state = SHARED;
                  else if (COMMAND == 5)  next_state = MODIFIED;  // not sure because should not happen?
                  else if (COMMAND == 6)  next_state = INVALID;

      EXCLUSIVE:  if      (COMMAND == 0)  begin PASS2L1('L1DR'); next_state = EXCLUSIVE; end
                  else if (COMMAND == 1)  begin INVALIDATESHARED; WRITE2L2; next_state = MODIFIED; end
                  else if (COMMAND == 2)  begin PASS2L1('L1IR'); next_state = EXCLUSIVE; end
                  else if (COMMAND == 3)  next_state = INVALID;
                  else if (COMMAND == 4)  next_state = SHARED;
                  else if (COMMAND == 5)  next_state = EXCLUSIVE;  // not sure because should not happen?
                  else if (COMMAND == 6)  next_state = INVALID;

      SHARED:     if      (COMMAND == 0) begin
                    PASS2L1('L1DR'); // Push data onto L1BUS - this needs to be replaced with the appropriate operation
                    next_state = SHARED;
                  end
                  else if (COMMAND == 1) begin INVALIDATESHARED; WRITE2L2; next_state = MODIFIED; end
                  else if (COMMAND == 2) begin PASS2L1('L1IR'); next_state = SHARED; end
                  else if (COMMAND == 3)  next_state = SHARED;  // not sure because should not happen?
                  else if (COMMAND == 4)  next_state = SHARED;
                  else if (COMMAND == 5)  next_state = SHARED;  // not sure because should not happen?
                  else if (COMMAND == 6)  next_state = INVALID;

      INVALID:    if      (COMMAND == 0) begin // this procedures waits until an answer is recieved from the fsb before moving on.
                    FSBREAD(); // Push read request on shared bus to get requested data.
                    if    (HM >= 2'b1)    next_state = SHARED;
                    else if (HM = 2'b0)   next_state = EXCLUSIVE;
                    else                  next_state = INVALID;
                  end
                  else if (COMMAND == 1) begin next_state = MODIFIED; end // This needs more thought
                  else if (COMMAND == 2) begin
                    FSBREAD(); // Push read request on shared bus
                    if    (HM >= 2b'1)    next_state = SHARED;
                    else if (HM = 2'b0)   next_state = EXCLUSIVE;
                    else                  next_state = INVALID;
                  else if (COMMAND == 3)  next_state = INVALID;  // not sure because should not happen?
                  else if (COMMAND == 4)  next_state = SHARED;
                  else if (COMMAND == 5)  next_state = INVALID;  // not sure because should not happen?
                  else if (COMMAND == 6)  next_state = INVALID;
    endcase
  end
endmodule