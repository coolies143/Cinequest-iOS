//
//  ForumsViewController.m
//  CineQuest
//
//  Created by Loc Phan on 10/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ForumsViewController.h"
#import "LoadDataViewController.h"
#import "EventDetailViewController.h"
#import "Schedule.h"
#import "CinequestAppDelegate.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "DDXML.h"

@interface ForumsViewController (Private)
- (void)loadDataFromDatabase;
- (void)syncTableDataWithScheduler;
@end

@implementation ForumsViewController

#pragma mark -
#pragma mark Memory Management
@synthesize days;
@synthesize index;
@synthesize data;
@synthesize forumsTableView;
@synthesize activity;
@synthesize loadingLabel;
@synthesize SJSUIcon;
@synthesize CQIcon;
@synthesize offSeasonLabel;


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark -
#pragma mark UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Forums";
	
	delegate = appDelegate;
	mySchedule = delegate.mySchedule;
	
	// Initialize data and days
	data = [[NSMutableDictionary alloc] init];
	days = [[NSMutableArray alloc] init];
	index = [[NSMutableArray alloc] init];
	backedUpDays	= [[NSMutableArray alloc] init];
	backedUpIndex	= [[NSMutableArray alloc] init];
	backedUpData	= [[NSMutableDictionary alloc] init]; 
	
	if (delegate.isOffSeason) {
		[activity stopAnimating];
		loadingLabel.hidden = YES;
		offSeasonLabel.hidden = NO;
		self.forumsTableView.hidden = YES;
		return;
	}
	
	// Create add button 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
																			   style:UIBarButtonItemStyleDone
																			  target:self
																			  action:@selector(addEvents:)];
	
	// Refine button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(refine:)];
	
	[self reloadData:nil];
	
}
- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *tableSelection = [self.forumsTableView indexPathForSelectedRow];
    [self.forumsTableView deselectRowAtIndexPath:tableSelection animated:NO];
    
	[self syncTableDataWithScheduler];
}
#pragma mark -
#pragma mark Private Methods
- (void)syncTableDataWithScheduler {
	NSUInteger i, count = [mySchedule count];
	
	// Sync current data
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *event = [rows objectAtIndex:row];
			//event.isSelected = NO;
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				//NSLog(@"obj id:%d, event id:%d",obj.ID,event.ID);
				if (obj.ID == event.ID) 
				{
					//NSLog(@"Added: %@. Time: %@",obj.title,obj.timeString);
					event.isSelected = YES;
				}
				
			}
			
		}
	}
	
	// Sync backedUp Data
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSArray *rows = [backedUpData objectForKey:day];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *event = [rows objectAtIndex:row];
			//event.isSelected = NO;
			for (i = 0; i < count; i++) 
			{
				Schedule *obj = [mySchedule objectAtIndex:i];
				if (obj.ID == event.ID) 
				{
					//NSLog(@"Added: %@.",obj.title);
					event.isSelected = YES;
					
				}
			}
			
		}
	}
}
- (void)startParsingXML {
	@autoreleasepool {
		NSURL *link = [NSURL URLWithString:FORUMS];
		NSData *xmldata = [NSData dataWithContentsOfURL:link];
		
		DDXMLDocument *forumsxmlDoc = [[DDXMLDocument alloc] initWithData:xmldata options:0 error:nil];
		DDXMLNode *rootElement = [forumsxmlDoc rootElement];
		
		int childCount = [rootElement childCount];
		NSString *previousDay = @"empty";
		NSMutableArray *tempArray = [[NSMutableArray alloc] init];
		//NSLog(@"%d",childCount);
		for (int i = 0; i < childCount; i++) {
			DDXMLElement *child = (DDXMLElement*)[rootElement childAtIndex:i];
			NSDictionary *attributes;
			if ([child respondsToSelector:@selector(attributesAsDictionary)]) {
				attributes = [child attributesAsDictionary];
			} else {
				continue;
			}
			
			NSString *ID		= [attributes objectForKey:@"schedule_id"];
			NSString *prg_id	= [attributes objectForKey:@"program_item_id"];
			NSString *type		= [attributes objectForKey:@"type"];
			NSString *title		= [attributes objectForKey:@"title"];
			NSString *start		= [attributes objectForKey:@"start_time"];
			NSString *end		= [attributes objectForKey:@"end_time"];
			NSString *venue		= [attributes objectForKey:@"venue"];
			
			Schedule *forum		= [[Schedule alloc] init];
			
			forum.ID			= [ID intValue];
			forum.prog_id		= [prg_id intValue];
			
			forum.type		= type;
			forum.title		= title;
			forum.venue		= venue;
			
			//Start time
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			NSDate *date = [dateFormatter dateFromString:start];
			forum.date = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			forum.timeString = [dateFormatter stringFromDate:date];
			//Date
			[dateFormatter setDateFormat:@"EEEE, MMMM d"];
			NSString *dateString = [dateFormatter stringFromDate:date];
			forum.dateString = dateString;
			//End Time
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			date = [dateFormatter dateFromString:end];
			forum.endDate = date;
			[dateFormatter setDateFormat:@"hh:mm a"];
			forum.endTimeString = [dateFormatter stringFromDate:date];
			
			if (![previousDay isEqualToString:dateString]) 
			{
				[data setObject:tempArray forKey:previousDay];
				previousDay = [[NSString alloc] initWithString:dateString];
				[days addObject:previousDay];
				
				[index addObject:[[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]];
				
				//NSLog(@"%@", [[previousDay componentsSeparatedByString:@" "] objectAtIndex: 2]);
				
				tempArray = [[NSMutableArray alloc] init];
				[tempArray addObject:forum];
			} else {
				[tempArray addObject:forum];
			}
			
			
		}
		[data setObject:tempArray forKey:previousDay];
		
		// back up current data
		backedUpDays	= [[NSMutableArray alloc] initWithArray:days copyItems:YES];
		backedUpIndex	= [[NSMutableArray alloc] initWithArray:index copyItems:YES];
		backedUpData	= [[NSMutableDictionary alloc] initWithDictionary:data copyItems:YES]; 
		
		[self.forumsTableView reloadData];
		self.forumsTableView.hidden = NO;
		CQIcon.alpha = 0.2;
		SJSUIcon.alpha = 0.2;
		loadingLabel.hidden = YES;
		[activity stopAnimating];
		self.navigationItem.leftBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		
		self.forumsTableView.tableHeaderView = nil; // To enable "Reload button", remove this line and uncomment 3 lines below
	//[self.forumsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
	//					 atScrollPosition:UITableViewScrollPositionTop
	//							 animated:NO];
	
	}
}
- (void)checkBoxButtonTapped:(id)sender event:(id)touchEvent {
	
	NSSet *touches = [touchEvent allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.forumsTableView];
	NSIndexPath *indexPath = [self.forumsTableView indexPathForRowAtPoint:currentTouchPosition];
	int row = [indexPath row];
	int section = [indexPath section];
	
	if (indexPath != nil)
	{
		// get date
		NSString *dateString = [days objectAtIndex:section];
		
		// get film objects using dateString
		NSMutableArray *events = [data objectForKey:dateString];
		Schedule *event = [events objectAtIndex:row];
		
		// set checkBox's status
		BOOL checked = event.isSelected;
		event.isSelected = !checked;
		
		// get the current cell and the checkbox button 
		UITableViewCell *currentCell = [self.forumsTableView cellForRowAtIndexPath:indexPath];
		UIButton *checkBoxButton = (UIButton*)[currentCell viewWithTag:CELL_BUTTON_TAG];
		
		// set button's image
		UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"];
		[checkBoxButton setImage:buttonImage forState:UIControlStateNormal];
		
		for (int section = 0; section < [days count]; section++) 
		{
			NSString *day = [days objectAtIndex:section];
			NSMutableArray *rows = [data objectForKey:day];
			for (int row = 0; row < [rows count]; row++) 
			{
				Schedule *aRandomEvent = [rows objectAtIndex:row];
				if (aRandomEvent.ID == event.ID) {
					aRandomEvent.isSelected = event.isSelected;
				}
				
			}
		}
	}
	
}
#pragma mark -
#pragma mark Actions
- (IBAction)reloadData:(id)sender {
	if (self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																				  style:UIBarButtonItemStylePlain
																				 target:self
																				 action:@selector(refine:)];
	}
	
	[days removeAllObjects];
	[data removeAllObjects];
	[index removeAllObjects];
	
	self.forumsTableView.hidden = YES;
	[activity startAnimating];
	loadingLabel.hidden = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	[NSThread detachNewThreadSelector:@selector(startParsingXML) toTarget:self withObject:nil];
}
- (void)addEvents:(id)sender {
	int counter = 0;
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		for (int row = 0; row < [rows count];row++ ) {
			Schedule *item = [rows objectAtIndex:row];
			if (item.isSelected) 
			{
				//NSLog(@"%@",item.title);
				Schedule *schedule = item;
				
				BOOL isAlreadyAdded = NO;
				for (int i=0; i < [mySchedule count]; i++) {
					Schedule *obj = [mySchedule objectAtIndex:i];
					if (obj.ID == schedule.ID) {
						isAlreadyAdded = YES;
						//NSLog(@"%@ ID: %d",schedule.title,schedule.ID);
						break;
					}
				}
				if (!isAlreadyAdded) 
				{
					[mySchedule addObject:schedule];
					counter++;
				}
			}
		}
	}
	[self syncTableDataWithScheduler];
	[self.forumsTableView reloadData];
	if (counter != 0) {
		[delegate jumpToScheduler];
	}
}
- (void)refine:(id)sender {
	// Back button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(back:)];
	
	// Remove rows
	NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
	NSMutableArray *itemsBeingDeleted = [[NSMutableArray alloc] init];
	
	for (int section = 0; section < [days count]; section++)
	{
		NSString *day = [days objectAtIndex:section];
		NSMutableArray *rows = [data objectForKey:day];
		
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *item = [rows objectAtIndex:row];
			if (!item.isSelected) 
			{
				[indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
				[itemsBeingDeleted addObject:item];
			}
			else {
				//NSLog(@"%@ - %@",item.time,item.title);
			}
			
		}
		[rows removeObjectsInArray:itemsBeingDeleted];
		[itemsBeingDeleted removeAllObjects];
	}
	
	// Remove sections
	NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
	
	int i = 0;
	for (NSString *day in days) 
	{
		NSMutableArray *rows = [data objectForKey:day];
		if ([rows count] == EMPTY) 
		{
			[data removeObjectForKey:day];
			[indexSet addIndex:i];
		}
		i++;
	}
	[days removeObjectsAtIndexes:indexSet];
	[index removeObjectsAtIndexes:indexSet];
	
	// Start updating table
	[self.forumsTableView beginUpdates];
	
	[self.forumsTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:NO];
	
	[self.forumsTableView deleteSections:indexSet withRowAnimation:NO];
	
	[self.forumsTableView endUpdates];
	
	// add push animation
	CATransition *transition = [CATransition animation];
	transition.type = kCATransitionPush;
	transition.subtype = kCATransitionFromTop;
	transition.duration = 0.3;
	[[self.forumsTableView layer] addAnimation:transition forKey:nil];
	
	// reload data
	[self.forumsTableView reloadData];
}
- (void)back:(id)sender {
	// Refine button
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refine"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(refine:)];
	
	// reload data
	[days removeAllObjects];
	[index removeAllObjects];
	
	[days addObjectsFromArray:backedUpDays];
	[index addObjectsFromArray:backedUpIndex];
	
	for (int section = 0; section < [days count]; section++) 
	{
		NSString *day = [days objectAtIndex:section];
		NSArray *rows = [backedUpData objectForKey:day];
		NSMutableArray *array = [[NSMutableArray alloc] init];
		for (int row = 0; row < [rows count]; row++) 
		{
			Schedule *item = [rows objectAtIndex:row];
			[array addObject:item];
		}
		[data setObject:array forKey:day];
	}
	
	// push animation
	CATransition *transition = [CATransition animation];
	transition.type = kCATransitionPush;
	transition.subtype = kCATransitionFromBottom;
	transition.duration = 0.3;
	[[self.forumsTableView layer] addAnimation:transition forKey:nil];
	
	// reload table data
	[self.forumsTableView reloadData];
	
}
#pragma mark -
#pragma mark UITableView Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [days count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSString *day = [days objectAtIndex:section];
	NSMutableArray *forums = [data objectForKey:day];
	
    return [forums count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	NSMutableArray *events = [data objectForKey:date];
	Schedule *event = [events objectAtIndex:row];
	// get title
	NSString *displayString = [NSString stringWithFormat:@"%@",event.title];
    // set text color
	UIColor *textColor = [UIColor blackColor];
	
	// check if current cell is already added to mySchedule
	// if it is, display it as blue
	NSUInteger i, count = [mySchedule count];
	for (i = 0; i < count; i++) {
		Schedule *obj = [mySchedule objectAtIndex:i];
		
		if (obj.ID == event.ID) 
		{
			//NSLog(@"%@ was added.",obj.title);
			textColor = [UIColor blueColor];
			event.isSelected = YES;
			break;
		}
	}
	
	// get checkbox status
	BOOL checked = event.isSelected;
	UIImage *buttonImage = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
	
	UILabel *titleLabel;
	UILabel *timeLabel;
	UILabel *venueLabel;
	UIButton *checkButton;
	
	UITableViewCell *tempCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (tempCell == nil) {
		tempCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
										   reuseIdentifier:CellIdentifier];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,2,230,20)];
		titleLabel.tag = CELL_TITLE_LABEL_TAG;
		[tempCell.contentView addSubview:titleLabel];
		
		timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50,21,150,20)];
		timeLabel.tag = CELL_TIME_LABEL_TAG;
		[tempCell.contentView addSubview:timeLabel];
		
		venueLabel = [[UILabel alloc] initWithFrame:CGRectMake(210,21,100,20)];
		venueLabel.tag = CELL_VENUE_LABEL_TAG;
		[tempCell.contentView addSubview:venueLabel];
		
		checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
		checkButton.frame = CGRectMake(0,0,50,50);
		[checkButton setImage:buttonImage forState:UIControlStateNormal];
		
		[checkButton addTarget:self 
						action:@selector(checkBoxButtonTapped:event:)
			  forControlEvents:UIControlEventTouchUpInside];
		
		checkButton.backgroundColor = [UIColor clearColor];
		checkButton.tag = CELL_BUTTON_TAG;
		[tempCell.contentView addSubview:checkButton];
		
	}
	
	titleLabel = (UILabel*)[tempCell viewWithTag:CELL_TITLE_LABEL_TAG];
	titleLabel.text = displayString;
	titleLabel.textColor = textColor;
	
	timeLabel = (UILabel*)[tempCell viewWithTag:CELL_TIME_LABEL_TAG];
	timeLabel.text = [NSString stringWithFormat:@"Time: %@ - %@",event.timeString,event.endTimeString];
	timeLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	timeLabel.textColor = textColor;
	
	venueLabel = (UILabel*)[tempCell viewWithTag:CELL_VENUE_LABEL_TAG];
	venueLabel.text = [NSString stringWithFormat:@"Venue: %@",event.venue];
	venueLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	venueLabel.textColor = textColor;
	
	checkButton = (UIButton*)[tempCell viewWithTag:CELL_BUTTON_TAG];
	[checkButton setImage:buttonImage forState:UIControlStateNormal];
	
	if (textColor == [UIColor blueColor]) {
		checkButton.userInteractionEnabled = NO;
	} else {
		checkButton.userInteractionEnabled = YES;
	}
	
    return tempCell;
}
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *day = [days objectAtIndex:section];
	return day;
}
- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
	return index;
}
#pragma mark -
#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	
	NSUInteger section = [indexPath section];
	NSUInteger row = [indexPath row];
	
	NSString *date = [days objectAtIndex:section];
	
	NSMutableArray *forums = [data objectForKey:date];
	
	Schedule *forum = [forums objectAtIndex:row];
	
	NSString *link = [NSString stringWithFormat:@"%@%d",DETAILFORITEM, forum.prog_id];
	
	EventDetailViewController *eventDetail = [[EventDetailViewController alloc] initWithTitle:forum.title
																				andDataObject:forum
																					   andURL:[NSURL URLWithString:link]];
	eventDetail.displayAddButton = YES;

	app.networkActivityIndicatorVisible = YES;
	
	[self.navigationController pushViewController:eventDetail animated:YES];
	
	
	//NSLog(@"%@%d",DETAILFORITEM, forum.ID);
}

@end

