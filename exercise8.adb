with Ada.Text_IO, Ada.Integer_Text_IO, Ada.Numerics.Float_Random;
use  Ada.Text_IO, Ada.Integer_Text_IO, Ada.Numerics.Float_Random;

procedure exercise8 is

    Count_Failed    : exception;
    Gen             : Generator;    -- Random number generator

    protected type Transaction_Manager (N : Positive) is
        entry Finished;
	entry Wait_Until_Aborted;
        function Commit return Boolean;
        procedure Signal_Abort;
    private
        Finished_Gate_Open  : Boolean := False;
        Aborted             : Boolean := False;
        Should_Commit       : Boolean := False;
    end Transaction_Manager;
    protected body Transaction_Manager is
        entry Finished when Finished_Gate_Open or Finished'Count = N is
        begin
      		Finished_Gate_Open := true;
      	
      		if Finished'Count = 0 then
      			Finished_Gate_Open := False;
      		end if;
			Aborted := False;
        end Finished;
	
        entry Wait_Until_Aborted when Aborted is
        begin
			if Wait_Until_Aborted'Count = 0 then
				Put_Line("All workers are aborted");
			end if;
        end Wait_Until_Aborted;

        procedure Signal_Abort is
        begin
            Aborted := True;
        end Signal_Abort;

        function Commit return Boolean is
        begin
            return Should_Commit;
        end Commit;
        
    end Transaction_Manager;
    
    function Unreliable_Slow_Add (x : Integer) return Integer is
    Error_Rate : Constant := 0.15;  -- (between 0 and 1)
	Result : Integer := 0;
    begin
		if Random(Gen) < Error_Rate then
			delay Duration(0.5 * Random(Gen));
			raise Count_Failed;
		else
			delay Duration(3.0 + 2.0 * Random(Gen));
			Result := x + 10;
		end if;
		return Result;
    end Unreliable_Slow_Add;

    task type Transaction_Worker (Initial : Integer; Manager : access Transaction_Manager);
    task body Transaction_Worker is
        Num         : Integer   := Initial;
        Prev        : Integer   := Num;
        Round_Num   : Integer   := 0;
		Error       : exception;
    begin
        Put_Line ("Worker" & Integer'Image(Initial) & " started");

        loop
			select 
				Manager.Wait_Until_Aborted;
				Num := Prev + 5;
			then abort
				Put_Line ("Worker" & Integer'Image(Initial) & " started round" & Integer'Image(Round_Num));
				Round_Num := Round_Num + 1;
				begin
					Num := Unreliable_Slow_Add(Num);
				exception
					when Count_Failed =>
					Put_Line("Worker" & Integer'Image(Initial) & " aborted");
					Manager.Signal_Abort;
				end;	    
			end select;

			Put_Line ("Worker" & Integer'Image(Initial) & " value is" & Integer'Image(Num));

			Manager.Finished;

			Prev := Num;
			delay 0.5;
        end loop;
    end Transaction_Worker;

    Manager : aliased Transaction_Manager (3);

    Worker_1 : Transaction_Worker (0, Manager'Access);
    Worker_2 : Transaction_Worker (1, Manager'Access);
    Worker_3 : Transaction_Worker (2, Manager'Access);

begin
    Reset(Gen); -- Seed the random number generator
end exercise8;
