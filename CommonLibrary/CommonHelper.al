codeunit 5445558 "LKN Common Helper"
{
    Access = Public;

    procedure GetFormattedDateTime(InputDateTime: DateTime): Text
    begin
        exit(Format(InputDateTime, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2>'));
    end;

    procedure ValidateEmail(Email: Text): Boolean
    begin
        exit(Email.Contains('@') and (Email.IndexOf('@') > 1) and (Email.IndexOf('@') < StrLen(Email)));
    end;

    procedure GenerateRandomGuid(): Guid
    var
        TempGuid: Guid;
    begin
        TempGuid := CreateGuid();
        exit(TempGuid);
    end;

    procedure SafeDivision(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        if Denominator = 0 then
            exit(0);
        exit(Numerator / Denominator);
    end;
}