Runtime:
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
Unable to simultaneously satisfy constraints.
    Probably at least one of the constraints in the following list is one you don't want. 
    Try this: 
        (1) look at each constraint and try to figure out which you don't expect; 
        (2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x600002294cd0 'accessoryView.bottom' _UIRemoteKeyboardPlaceholderView:0x104825480.bottom == _UIKBCompatInputView:0x104849460.top   (active)>",
    "<NSLayoutConstraint:0x6000022e1c20 'assistantHeight' SystemInputAssistantView.height == 72   (active, names: SystemInputAssistantView:0x104bd3480 )>",
    "<NSLayoutConstraint:0x6000022969e0 'assistantView.bottom' SystemInputAssistantView.bottom == _UIKBCompatInputView:0x104849460.top   (active, names: SystemInputAssistantView:0x104bd3480 )>",
    "<NSLayoutConstraint:0x6000022968a0 'assistantView.top' V:[_UIRemoteKeyboardPlaceholderView:0x104825480]-(0)-[SystemInputAssistantView]   (active, names: SystemInputAssistantView:0x104bd3480 )>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x6000022e1c20 'assistantHeight' SystemInputAssistantView.height == 72   (active, names: SystemInputAssistantView:0x104bd3480 )>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.


Habit completion -> undo button for undoing habits -> cannot press the complete button again to uncomplete(?) the habit



